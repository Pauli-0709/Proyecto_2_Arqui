// GEMM paralelo por filas (OpenMP), variante i-k-j: B y C se recorren de forma contigua.
// Variante comparativa de src/gemm_paralelo.c; misma interfaz, ROI y salida.
#include <errno.h>
#include <math.h>
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef USE_GEM5
#include <gem5/m5ops.h>
#endif

#define N_MAX 1024
#define HILOS_MAX 8

// Lee un entero en [1, maximo]; devuelve 0 si el argumento es invalido.
static int leer_entero(const char *texto, long maximo)
{
    if (texto[0] < '0' || texto[0] > '9') return 0;
    errno = 0;
    char *fin;
    long valor = strtol(texto, &fin, 10);
    if (errno != 0 || *fin != '\0' || valor < 1 || valor > maximo) return 0;
    return (int)valor;
}

// Mismas entradas deterministas que gemm_paralelo.c.
static void inicializar(int n, float *a, float *b, float *c)
{
    for (int fila = 0; fila < n; fila++)
        for (int columna = 0; columna < n; columna++) {
            size_t pos = (size_t)fila * n + columna;
            a[pos] = (float)((17 * fila + 13 * columna + 1) % 31 - 15) / 16.0f;
            b[pos] = (float)((7 * fila + 19 * columna + 3) % 29 - 14) / 16.0f;
            c[pos] = 0.0f;
        }
}

// Calcula la fila i de C con orden i-k-j 
static void calcular_fila(int n, int i, const float *a, const float *b, float *c)
{
    float *fila_c = c + (size_t)i * n;
    for (int j = 0; j < n; j++) fila_c[j] = 0.0f;
    for (int k = 0; k < n; k++) {
        const float aik = a[(size_t)i * n + k];
        const float *fila_b = b + (size_t)k * n;
        for (int j = 0; j < n; j++) fila_c[j] += aik * fila_b[j];
    }
}

// Reparte filas completas entre los hilos y devuelve cuantos recibieron trabajo.
static int multiplicar(int n, int hilos, const float *a, const float *b, float *c)
{
    int hilos_usados = 0;
#pragma omp parallel num_threads(hilos) reduction(+ : hilos_usados)
    {
        int trabajo = 0;
#pragma omp for schedule(static)
        for (int fila = 0; fila < n; fila++) {
            trabajo = 1;
            calcular_fila(n, fila, a, b, c);
        }
        hilos_usados += trabajo;
    }
    return hilos_usados;
}

// Referencia serial en double, fuera de la ROI.
static int verificar(int n, const float *a, const float *b, const float *c)
{
    int errores = 0;
    for (int fila = 0; fila < n; fila++)
        for (int columna = 0; columna < n; columna++) {
            double esperado = 0.0;
            for (int k = 0; k < n; k++)
                esperado += (double)a[(size_t)fila * n + k] * (double)b[(size_t)k * n + columna];
            double obtenido = c[(size_t)fila * n + columna];
            double tolerancia = 1e-5 + 1e-5 * fabs(esperado);
            if (!isfinite(obtenido) || fabs(obtenido - esperado) > tolerancia) errores++;
        }
    return errores;
}

int main(int argc, char *argv[])
{
    if (argc != 3) {
        fprintf(stderr, "Uso: %s N HILOS (N de 1 a %d, HILOS de 1 a %d)\n", argv[0], N_MAX, HILOS_MAX);
        return EXIT_FAILURE;
    }
    int n = leer_entero(argv[1], N_MAX);
    int hilos = leer_entero(argv[2], HILOS_MAX);
    if (n == 0 || hilos == 0 || hilos > n) {
        fprintf(stderr, "Error: use 1 <= N <= %d y 1 <= HILOS <= %d, con HILOS <= N.\n", N_MAX, HILOS_MAX);
        return EXIT_FAILURE;
    }

    size_t elementos = (size_t)n * n;
    float *a = malloc(elementos * sizeof(*a));
    float *b = malloc(elementos * sizeof(*b));
    float *c = malloc(elementos * sizeof(*c));
    if (!a || !b || !c) {
        fprintf(stderr, "Error al reservar memoria.\n");
        free(a); free(b); free(c);
        return EXIT_FAILURE;
    }

    inicializar(n, a, b, c);
    omp_set_dynamic(0);

#ifdef USE_GEM5
    m5_reset_stats(0, 0);
#endif
    int hilos_usados = multiplicar(n, hilos, a, b, c);
#ifdef USE_GEM5
    m5_dump_stats(0, 0);
#endif

    int errores = verificar(n, a, b, c);
    int correcto = errores == 0 && hilos_usados == hilos;
    printf("N=%d HILOS=%d HILOS_USADOS=%d CHECK=%s errores=%d\n",
           n, hilos, hilos_usados, correcto ? "PASS" : "FAIL", errores);

    free(a); free(b); free(c);
    return correcto ? EXIT_SUCCESS : EXIT_FAILURE;
}
