// E6: GEMM con SVE y OpenMP (reparto estatico por filas de C).
// Uso: gemm_paralelo_sve N HILOS
#include <errno.h>
#include <math.h>
#include <omp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <arm_sve.h>
#ifdef USE_GEM5
#include <gem5/m5ops.h>
#endif

#define N_MAX 1024
#define HILOS_MAX 8
#define FILAS_VERIFICAR_MAX 256 // Hasta este N se verifica toda la matriz.
#define FILAS_MUESTRA 8         // Con N mayor se verifica una muestra de filas.

// Convierte texto a entero dentro de [min, max]; devuelve 0 si es invalido.
static int leer_entero(const char *texto, size_t min, size_t max, size_t *salida)
{
    errno = 0;
    char *fin = NULL;
    unsigned long valor = strtoul(texto, &fin, 10);
    if (errno != 0 || fin == texto || *fin != '\0' || valor < min || valor > max) {
        return 0;
    }
    *salida = (size_t)valor;
    return 1;
}

// Reserva alineada a la linea de cache de 64 bytes.
static void *reservar(size_t bytes)
{
#ifdef E6_SIN_ALINEAR
    return malloc(bytes);   /* control: igual que gemm_sve.c de E3 */
#else
    size_t redondeado = (bytes + 63u) & ~(size_t)63u;
    return aligned_alloc(64, redondeado);
#endif
}
// Mismas formulas que gemm_sve.c, para que los datos coincidan con E3.
static void inicializar(size_t n, float *a, float *b, float *c)
{
    for (size_t i = 0; i < n; i++) {
        for (size_t j = 0; j < n; j++) {
            size_t p = i * n + j;
            a[p] = (float)((int)((17 * i + 13 * j + 1) % 31) - 15) / 16.0f;
            b[p] = (float)((int)((7 * i + 19 * j + 3) % 29) - 14) / 16.0f;
            c[p] = 0.0f;
        }
    }
}

// Calcula una fila de C con vectores SVE (productos punto por bloques de VL columnas).
__attribute__((noinline))
static void fila_sve(size_t n, size_t i, const float *restrict a,
                     const float *restrict b, float *restrict c)
{
    const size_t paso = (size_t)svcntw();
    for (size_t j = 0; j < n; j += paso) {
        svbool_t activas = svwhilelt_b32_u64((uint64_t)j, (uint64_t)n);
        svfloat32_t sumas = svdup_n_f32(0.0f);
        for (size_t k = 0; k < n; k++) {
            svfloat32_t fila_b = svld1_f32(activas, &b[k * n + j]);
            svfloat32_t productos = svmul_n_f32_x(activas, fila_b, a[i * n + k]);
            sumas = svadd_f32_m(activas, sumas, productos);
        }
        svst1_f32(activas, &c[i * n + j], sumas);
    }
}

// Reparte las filas entre los hilos y registra cuantos hilos trabajaron.
__attribute__((noinline))
static int gemm_sve_omp(size_t n, int hilos, const float *a, const float *b, float *c)
{
    unsigned char vistos[HILOS_MAX] = {0};

    #pragma omp parallel num_threads(hilos)
    {
        vistos[omp_get_thread_num()] = 1;
        #pragma omp for schedule(static)
        for (size_t i = 0; i < n; i++) {
            fila_sve(n, i, a, b, c);
        }
    }

    int usados = 0;
    for (int t = 0; t < HILOS_MAX; t++) {
        usados += vistos[t];
    }
    return usados;
}

// Compara filas de C contra una referencia en double (fuera de la ROI).
static size_t verificar(size_t n, const float *a, const float *b, const float *c,
                        double *error_maximo)
{
    size_t errores = 0;
    size_t paso = n <= FILAS_VERIFICAR_MAX ? 1 : n / FILAS_MUESTRA;
    *error_maximo = 0.0;

    for (size_t i = 0; i < n; i += paso) {
        for (size_t j = 0; j < n; j++) {
            double esperado = 0.0;
            for (size_t k = 0; k < n; k++) {
                esperado += (double)a[i * n + k] * (double)b[k * n + j];
            }
            double obtenido = (double)c[i * n + j];
            double error = fabs(obtenido - esperado);
            if (!isfinite(obtenido) || error > 1e-5 + 1e-5 * fabs(esperado)) {
                errores++;
            }
            if (error > *error_maximo) {
                *error_maximo = error;
            }
        }
    }
    return errores;
}

int main(int argc, char *argv[])
{
    size_t n = 0, hilos_pedidos = 0;
    if (argc != 3 || !leer_entero(argv[1], 1, N_MAX, &n)
        || !leer_entero(argv[2], 1, HILOS_MAX, &hilos_pedidos)) {
        fprintf(stderr, "Uso: %s N HILOS (N 1..%d, HILOS 1..%d)\n", argv[0], N_MAX, HILOS_MAX);
        return EXIT_FAILURE;
    }

    size_t bytes = n * n * sizeof(float);
    float *a = reservar(bytes), *b = reservar(bytes), *c = reservar(bytes);
    if (!a || !b || !c) {
        fprintf(stderr, "Error al reservar memoria.\n");
        free(a); free(b); free(c);
        return EXIT_FAILURE;
    }
    inicializar(n, a, b, c);
    printf("SVE VL_BITS=%zu ELEMENTOS_FLOAT=%zu\n", (size_t)svcntw() * 32, (size_t)svcntw());

#ifdef USE_GEM5
    m5_reset_stats(0, 0);
#endif
    int usados = gemm_sve_omp(n, (int)hilos_pedidos, a, b, c);
#ifdef USE_GEM5
    m5_dump_stats(0, 0);
#endif

    double error_maximo = 0.0;
    size_t errores = verificar(n, a, b, c, &error_maximo);
    int correcto = errores == 0 && usados == (int)hilos_pedidos;
    // La linea exacta de exito la exigen los scripts de validacion.
    printf("N=%zu HILOS=%zu HILOS_USADOS=%d CHECK=%s errores=%zu\n",
           n, hilos_pedidos, usados, correcto ? "PASS" : "FAIL", errores);
    printf("max_abs_error=%.9g\n", error_maximo);

    free(a); free(b); free(c);
    return correcto ? EXIT_SUCCESS : EXIT_FAILURE;
}
