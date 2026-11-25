//	Bibliotecas a utilizar
#include <errno.h>  // Permite detectar desbordamientos al momento de leer los distintos argumentos
#include <math.h>   // Declara las instrucciones fabs y isfinite que sirven para comprobar los resultados
#include <omp.h>    // Declara las funciones de OpenMP
#include <stdio.h>  // Permite imprimir mensajes y los distintos resultados
#include <stdlib.h> // Permite reservar la memoria y poder convertir los argumentos

#ifdef USE_GEM5 // Habilita las diversas marcas al momento de compilar para el simulador gem5
#include <gem5/m5ops.h> // Declara las operaciones de estadisticas de gem5
#endif // Termina la inclusion de gem5

//---------------------------------------------------------------------------------------------------------
// Funcion auxiliar leer_entero
// Objetivo: lee un entero positivo y la misma devuelve 0 si el argumento es invalido
static int leer_entero(const char *texto, long maximo){
    if (texto[0] < '0' || texto[0] > '9') { // Verifica que el argumento empiece con un digito
        return 0; // Rechaza cualquier otro tipo de argumento
    }

    errno = 0; // Variable que limpia los errores de las conversion anteriores
    char *fin; // Variable que guarda la posicion donde se detuvo la conversion
    long valor = strtol(texto, &fin, 10); // Variable para convertir el texto en base 10


    if (errno != 0 || *fin != '\0' || valor < 1 || valor > maximo) { // Se comprueba el valor y el texto sobrante
        return 0; // Este returno es para indicar que el argumento esta fuera del rango admitido
    }

    return (int)valor; // Devuelve el entero validado y correcto
}


//----------------------------------------------------------------------------------------------------------------------------------
// Funcion auxiliar - inicializar
// Objetivo: utiliza las mismas entradas deterministas que el simulador GEMM escalar del repositorio y las inicializa
static void inicializar(int n, float *a, float *b, float *c){
    for (int fila = 0; fila < n; fila++) { // Este for recorre las filas de las matrices
        for (int columna = 0; columna < n; columna++) { // Este for recorre las columnas de la fila
            int posicion = fila * n + columna; // Se calcula el indice especifico en el arreglo
            a[posicion] = (float)((17 * fila + 13 * columna + 1) % 31 - 15) / 16.0f; // Se asigna el valor de A
            b[posicion] = (float)((7 * fila + 19 * columna + 3) % 29 - 14) / 16.0f; // Se asigna el valor de B
            c[posicion] = 0.0f; // Se inicializa posicion de salida antes de medir
        }
    }
}


//-----------------------------------------------------------------------------------------------------------------------
// Funcion auxiliar - multiplicar
// Objetivo: esta reparte  las distintas filas completas entre los hilos y devuelve cuantos participaron
static int multiplicar(int n, int hilos, const float *a, const float *b, float *c){
    int hilos_usados = 0; // Variable que registra cuantos hilos recibieron al menos una fila

    #pragma omp parallel num_threads(hilos) reduction(+:hilos_usados) // Instruccion que crea el equipo y suma las contribuciones
    {
        int trabajo = 0; // Variable para cada hilo que empieza sin filas procesadas
        #pragma omp for schedule(static) // Instruccion que reparte filas por adelantado de forma equilibrada


        for (int fila = 0; fila < n; fila++) { // Este for recorre cada fila de C que pertenece a un solo hilo
            trabajo = 1; // Se registra que este hilo recibio trabajo

            for (int columna = 0; columna < n; columna++) { // Este for calcula todas las columnas de la fila
                float suma = 0.0f; // Se acumula el producto

                for (int k = 0; k < n; k++) { // Este for recorre la fila de A y la columna de B
                    suma += a[fila * n + k] * b[k * n + columna]; // Se actualiza la variable, puesto que realiza la suma de un producto a la celda
                }

                c[fila * n + columna] = suma; // Guarda la celda antes calculada
            }
        }

        hilos_usados += trabajo; // Se actualiza variable
    }
    return hilos_usados; // Devuelve el numero de hilos que procesaron filas
}


//------------------------------------------------------------------------------------------------------------------------------
// Funcion auxiliar - verificar
// Objetivo: calcular una referencia serial de tipo double y que la misma va a comparar cada celda fuera de la ROI
static int verificar(int n, const float *a, const float *b, const float *c){
    int errores = 0; // Se declara la variable que cuenta las celdas fuera de tolerancia


    for (int columna = 0; columna < n; columna++) { // For para recorrer las columnas
        for (int fila = 0; fila < n; fila++) { // For para recorrer las filas de cada columna
            double esperado = 0.0; // Se declara la variable que sirve como la referencia de la celda

            for (int k = 0; k < n; k++) { // For para recalcular el producto punto en serie
                esperado += (double)a[fila * n + k] * (double)b[k * n + columna]; // Acumula en double.
            }



            double obtenido = c[fila * n + columna]; // Variable que lee el valor de la multiplicacion
            double tolerancia = 1e-5 + 1e-5 * fabs(esperado); // Se aplica la tolerancia del GEMM escalar
            if (!isfinite(obtenido) || fabs(obtenido - esperado) > tolerancia) { // If para detectar un resultado invalido
                errores++; // Se actualiza la variable, peusto que se registra la diferencia
            }
        }
    }
    return errores; // Devuelve el numero de celdas incorrectas
}




//---------------------------------------------------------------------------------------------------------------------------------
// Funcion principal
int main(int argc, char *argv[]) // Esta funcion primero recibe N y el numero de hilos por consola
{
    if (argc != 3) { // Verifica que sean exactamente dos argumentos
        fprintf(stderr, "Uso: %s N HILOS (N de 1 a 1024, HILOS de 1 a 8)\n", argv[0]); // Print en pantallla del error y explicacion del formato
        return EXIT_FAILURE; // Termina por uso incorrecto
    }


    int n = leer_entero(argv[1], 1024); // Variable que lee el numero de filas y columnas
    int hilos = leer_entero(argv[2], 8); // Variable que lee el numero de hilos solicitados

    if (n == 0 || hilos == 0 || hilos > n) { // Se verifica que exista al menos una fila por hilo
        fprintf(stderr, "Error: use 1 <= N <= 1024 y 1 <= HILOS <= 8, con HILOS <= N.\n"); // Print en pantalla y se explica los limites
        return EXIT_FAILURE; // Termina por argumentos invalidos
    }


    size_t elementos = (size_t)n * n; // Variable que calcula las celdas de cada matriz

    // Reservar memoria
    float *a = malloc(elementos * sizeof(*a)); // Reservar la matriz de entrada A
    float *b = malloc(elementos * sizeof(*b)); // Reservar la matriz de entrada B
    float *c = malloc(elementos * sizeof(*c)); // Reservar la matriz de salida C

    if (a == NULL || b == NULL || c == NULL) { // Se comprueba si alguna reserva fallo
        fprintf(stderr, "Error al reservar memoria.\n"); // Print del fallo
        free(a); // Libera A si se pudo reservar
        free(b); // Libera B si se pudo reservar
        free(c); // Libera C si se pudo reservar
        return EXIT_FAILURE; // Termina por falta de memoria
    }


    inicializar(n, a, b, c); // Se llama a la funcion inicializar para preparar las matrices antes de la medicion
    omp_set_dynamic(0); // Instruccion que pide a OpenMP mantener el numero de hilos solicitado

#ifdef USE_GEM5 // Marcas de medicion al simular
    m5_reset_stats(0, 0); // Reinicia los contadores al comenzar la ROI
#endif // Termina la marca de inicio
    int hilos_usados = multiplicar(n, hilos, a, b, c); // Variable que mide el calculo y la gestion del equipo de hilos, con el llamado de la funcion auxiliar multiplicar
#ifdef USE_GEM5 // Usa el volcado de estadisticas al simular
    m5_dump_stats(0, 0); // Vuelca los contadores al terminar la ROI
#endif // Termina la marca de cierre


    int errores = verificar(n, a, b, c); // Variable que valida las celdas fuera de la ROI (funcion auxliar - verificar)
    int correcto = errores == 0 && hilos_usados == hilos; // Se exige que todos los resultados sean correctos, incluyendo todos los hilos

    printf("N=%d HILOS=%d HILOS_USADOS=%d CHECK=%s errores=%d\n", n, hilos, hilos_usados, correcto ? "PASS" : "FAIL", errores); // Print para generar el resultado de la prueba


#if defined(USE_GEM5) && defined(E5_RUBY) // Activa esta salida solo para el GEMM del experimento E5.
    if (fflush(stdout) == EOF || !correcto) { // Escribe el resultado y comunica un fallo si corresponde.
        m5_fail(0, EXIT_FAILURE); // Termina la simulacion con un error.
    } else {
        m5_exit(0); // Termina la simulacion Ruby antes del cierre normal de OpenMP.
    }
#endif


	//Se libera la memoria
    free(a); // Libera la matriz A
    free(b); // Libera la matriz B
    free(c); // Libera la matriz C

    return correcto ? EXIT_SUCCESS : EXIT_FAILURE; // Verifica el resultado obtenido
}
