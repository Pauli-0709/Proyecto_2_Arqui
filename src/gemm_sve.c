// Programa GEMM para el experimento de extensiones vectoriales SVE

/* La primer seccion de codigo va hacer lo siguiente:
 - Leer el tamano de las matrices
 - Preparar los distintos datos reproducibles
 - Poder calcular una matriz de referencia */

// NOTA: el calculo con las instrucciones SVE se va agregar en la siguiente seccion

//-------------------------------------------------------------------------------------------------------
// Bibliotecas del codigo
#include <stdio.h>		// Permite usar funciones de entrada y salida (printf, fprintf, stderr)
#include <stdlib.h>		// Permite gestionar la memoria dinámica (malloc, calloc, free) y las utilidades (strtoul)
#include <errno.h>		// Proporciona la variable 'errno' que sirva para detectar errores en operaciones del sistema
#include <math.h>		// Proporciona funciones y las macros matematicas (isfinite() que sirve para comprobar los numeros)

//-------------------------------------------------------------------------------------------------------
/*  Funcion de inicializar las matrices de entrada
	Objetivo: llenar las matrices A y B con valores iniciales y la matriz C con valores iguales a 0.
	Parametros:
	1-> n: tamano de la matriz (N X N)
	2-> a, b, c: punteros a los arreglos de las matrices */

static void inicializar(size_t n, float *a, float *b, float *c)
{
	// Bucle externo que itera sobre cada una de las filas de la matriz
    for (size_t i = 0; i < n; i++) {
    	// Bucle interno que itera sobre cada una de las columnas de la matriz
        for (size_t j = 0; j < n; j++) {
            size_t posicion = i * n + j;	// Calcula la posicion equivalente a (i, j)
            int valor_a = (int)((17 * i + 13 * j + 1) % 31) - 15;	// Valores random pero fijos para a, esto con el fin de que no cambien en cada ejecucion
            int valor_b = (int)((7 * i + 19 * j + 3) % 29) - 14;	// Valores random pero fijos para b, esto con el fin de que no cambien en cada ejecucion
            a[posicion] = (float)valor_a / 16.0f;	// Convierte el numero entero "a" decimal tipo float y lo divide entre 16.0 esto es con el fin de normalizarlo
            b[posicion] = (float)valor_b / 16.0f;	// Convierte el numero entero "b" decimal tipo float y lo divide entre 16.0 esto es con el fin de normalizarlo
            c[posicion] = 0.0f;	// Inicializa la matriz c de resultados con puros 0
        }
    }
}

//---------------------------------------------------------------------------------------------------------

/* Funciion para Calcular el resultado de referencia de C = A X B
   Objetivo: hacer la operacion de multiplicacion de matrices C = A x B
   Parametros:
   1-> n: tamano de las matrices (N x N -> n filas x n columnas)
   2-> a: puntero de la matriz A
   3-> b: puntero de la matriz B
   4-> referencia: puntero al bloque de memoria donde se va almacernar o guardar el resultado correcto*/
static void calcular_referencia(size_t n, const float *a, const float *b, double *referencia)
{
	// Algoritmo para la multiplicacion de matrices, el orden de los bucles es (j, k, i)
    for (size_t j = 0; j < n; j++) {
        for (size_t k = 0; k < n; k++) {
            for (size_t i = 0; i < n; i++) {
				// En esta seccion se realiza la multiplicacion y la va sumando al valor de referencia, ademas se realiza teniendo en cuenta el tipo float
                referencia[i * n + j] += (double)a[i * n + k] * (double)b[k * n + j];
            }
        }
    }
}

/* Funcion para leer el tamano solicitado y poder rechazar las entradas que son incorrectas
   Objetivo: leer el tamano N desde la consola cuando la persona ejecuta el programa
   - Retorna 1 si es exitoso
   - Retorna 0 si hay un error
   Parametros:
   1-> argc: contador de argumentos, numero de palabras/argumentos que escribio el usuario en la consola
   2-> argv:es un arreglo de strings (textos) con lo que el usuario escribio
   3-> n: puntero a la variable n que se declara en el main*/
static int leer_tamano(int argc, char *argv[], size_t *n)
{
	// Se comprueba si la persona no paso exactamente un argumento o si no empieza por un digito
    if (argc != 2 || argv[1][0] < '0' || argv[1][0] > '9') {
        fprintf(stderr, "Uso: %s N, con N entre 1 y 1024\n", argv[0]);	// Imprime en pantalla el error
        return 0;	// Senal de error
    }

	errno = 0;	// Reinicia la variable de error a 0
    char *fin = NULL;	// Puntero que guarda la posicion donde termina la leer el numero
    unsigned long valor = strtoul(argv[1], &fin, 10);	// convierte el string (texto) a un numero de tipo entero

/* IF para verificacion extra
   1-> errno != 0: existe un error de desbordamiento, en otras palabras es un numero muy grande
   2-> *fin != '\0': la persona coloca letras despues del numero, esto es un comportamiento incorrecto y que no se debe esperar
   3-> valor < 1 || valor > 1024: el numero ingresado esta fuera del rango permitido */
    if (errno != 0 || *fin != '\0' || valor < 1 || valor > 1024) {
        fprintf(stderr, "Error: N debe ser un entero entre 1 y 1024.\n");	// Impresion en pantalla del error (3)
        return 0;	// Senal de error
    }

    *n = (size_t)valor;	// Si todo esta correcto y el if no se activa, guarda el valor convertido que se brindo en los parametros
    return 1;	// Senal de exito
}

/* Funcion principal, que ejecuta la primera prueba de preparación.
   Proposito: es la rama principal del script.
   Parametros:
   1-> argc: # de argumentos que fueron recibidos
   2-> argv: arreglo de cadena de texto (strings) que contiene los argumentos, ademas del nombre de la funcion */
int main(int argc, char *argv[])
{
    size_t n;	// Variable para guardar el tamano de la matriz N X N

	// Este IF va a llamar la funcion auxiliar leer_tamano. Si esta funcion retorna 0 (error), el programa se detiene y muestra el error
    if (!leer_tamano(argc, argv, &n)) {
        return EXIT_FAILURE;	// Detiene el programa con un error
    }

    // Calcula cuantos elementos totalas va a tener cada matriz, es lo mismo que hacer un N al cuadrado
    size_t elementos = n * n;

	/* Asignacion de memoria dinamica
	   malloc: instruccion que reserva un bloque de memoria del tamano especifico (dado por elementos x bytes por elemento)
	   calloc: instruccion que reserva un bloque de memoria del tamano especifico y limpia la memroia poniendola toda en 0 */
    float *a = malloc(elementos * sizeof(*a));
    float *b = malloc(elementos * sizeof(*b));
    float *c = malloc(elementos * sizeof(*c));
    double *referencia = calloc(elementos, sizeof(*referencia));

	// Este IF es para comprobar si existe memoria RAM disponible, si es asi malloc/calloc devuelven un NULL
    if (a == NULL || b == NULL || c == NULL || referencia == NULL) {
        fprintf(stderr, "Error al reservar memoria para las matrices.\n");	// Se imprime el error en pantalla
		// Si el IF se ejecuta por el error de memoria, se libera cualquier memoria dinamica que si haya tenido exito
        free(a);
        free(b);
        free(c);
        free(referencia);

        return EXIT_FAILURE;	// Genera el fallo
    }

	// Llamado a las sub funciones
    inicializar(n, a, b, c);
    calcular_referencia(n, a, b, referencia);

    // Variable para validar que el calculado realizado es correcto
    double checksum = 0.0;	// Variable para guardar la suma de todos los resultados
    int referencia_valida = 1;	// Variable que funciona como una flag (1 = verdadera y 0 = falsa)

	// Recorre toda la matriz de resultado linealmente (de 0 hasta N X N)
    for (size_t p = 0; p < elementos; p++) {
		// La instruccion isfinite() comprueba que el numero no sea Infinito (Inf) ni "No es un Numero" (NaN).
        if (!isfinite(referencia[p])) {
            referencia_valida = 0;	// Si existe el error se actualiza la variable referencia_valida en 0
        }

        checksum += referencia[p];	// Suma el valor actual al total
    }

    printf("N=%zu REFERENCIA=%s checksum=%.17g\n", n, referencia_valida ? "FINITA" : "INVALIDA", checksum );	// Imprime en pantalla el resultado final del experimento

    // Liberar los espacios de memoria dinamica reservados antes de finalizar la ejecucion del programa
    free(a);
    free(b);
    free(c);
    free(referencia);

    return referencia_valida ? EXIT_SUCCESS : EXIT_FAILURE; // Termina el programa. Si fue valida, retorna exito o falsa (0); si no, retorna fallo o verdadera (1).
}
