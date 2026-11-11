// Programa GEMM con instrucciones vectoriales SVE

/* El siguiente codigo realiza las siguientes acciones:
 - Preparar las matrices a utilizar
 - Ejecuta la multiplicacion de matrices
 - Compara cada elemento de la matriz c contra una refencia calculada utilizando double */

// NOTA: cuando se compila con la herramienta de USE_GEM5, mide solamente la multiplicacion con el uso de las herramientas m5_reset_stats y m5_dump_stats.

//-------------------------------------------------------------------------------------------------------
// Bibliotecas del codigo
#include <stdio.h>		// Permite usar funciones de entrada y salida (printf, fprintf, stderr)
#include <stdlib.h>		// Permite gestionar la memoria dinámica (malloc, calloc, free) y las utilidades (strtoul)
#include <errno.h>		// Proporciona la variable 'errno' que sirva para detectar errores en operaciones del sistema
#include <math.h>		// Proporciona funciones y las macros matematicas (isfinite() que sirve para comprobar los numeros)
#include <stdint.h>	    // Define tipos enteros de tamano conocido
#include <arm_sve.h>    // Permite utilizar las operaciones vectoriales SVE de ARM
#ifdef USE_GEM5
#include <gem5/m5ops.h> // Incluye las funciones de medicion cuando se va a compilar para gem5
#endif

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

//-------------------------------------------------------------------------------------------------------------------------

/* Funcion que realiza la multiplicacion de matrices mediante instrucciones SVE
   Objetivo: se realiza esta multiplicacion con instrucciones SVE de ARM para de esta manera poder acelerar de gran manera el calculo
   - La logica es la de calcular C = A X  B, las cuales son matrices cuadradas N X N de tipo float, y se efectua procesando bloques de VL columnas a la vez,
     donde VL = svcntw() es el ancho del vector SVE. Asimismo, para cada fila (i) y cada bloque de columnas (j), se va acumulando en un vector el producto
     punto, en cada iteracion (k) carga el valor de la ecuacion B[k][j...j + Vl - 1], lo multiplica por el escalar A[i][k] y lo suma. Al final guarda el
     bloque en C[i][j....]. Finalmente se realiza un verificacion en el ultimo bloque de columnas para que no se salga de la matriz.
   Parametros:
   1-> n: dimension de las matrices (N X N)
   2-> a: puntero de la matriz a (solo es para la lectura)
   3-> b: puntero de la matriz b (solo es para la lectura)
   4-> c: puntero de la matriz c (esta va a guardar el resultado, por ende es de escritura) */
__attribute__((noinline))
void gemm_sve(size_t n, const float *a, const float *b, float *c)
{
    size_t elementos_vector = (size_t)svcntw();	// Consultar cuantos valores float de 32 bits caben en este vector

    // Recorre las distintas filas de la matriz de resultados
    for (size_t i = 0; i < n; i++) {

        // Recorre las distintas columnas del tamano del vector (las recorre por grupos)
        for (size_t j = 0; j < n; j += elementos_vector) {

            svbool_t activas = svwhilelt_b32_u64((uint64_t)j, (uint64_t)n);	// Activa solamente las posiciones que pertenecen a la matriz, esto con el fin de evitar que accede a un rango fuera del arreglo (se puede dar cuando el ultimo grupo tiene menos columnas que el vector)
            svfloat32_t sumas = svdup_n_f32(0.0f);	 // Iniciar en 0 las sumas de las columnas del grupo

            // Recorrer los elementos que forman cada producto punto
            for (size_t k = 0; k < n; k++) {

                svfloat32_t valores_b = svld1_f32(activas, &b[k * n + j]);	// Leer varias columnas consecutivas de la fila k de la matriz B
                svfloat32_t productos = svmul_n_f32_x(activas, valores_b, a[i * n + k]);	// Multiplicar esas columnas en especifico por cada elemento A[i][k]
                sumas = svadd_f32_m(activas, sumas, productos);	// Acumula los productos de las columnas bajo analisis o activas
            }

            svst1_f32(activas, &c[i * n + j], sumas);	// Guarda las columnas calculadas en la matriz c
        }
    }
}


//---------------------------------------------------------------------------------------------------------

/* Funciion para calcular el resultado de referencia de C = A X B
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
				// En esta seccion se realiza la multiplicacion y la va sumando al valor de referencia, ademas se realiza teniendo en cuenta que los numeros estan convertidos a double
                referencia[i * n + j] += (double)a[i * n + k] * (double)b[k * n + j];
            }
        }
    }
}

//-----------------------------------------------------------------------------------------------------------------------

/* Funcion que es para comparar cada elemento calculado con SVE contra la referencia.
   Objetivo: validar la exactitud matematica de la multiplicacion de matrices realizada con las instrucciones SVE
   Parametros:
   1-> n: dimension de las matrices (N X N)
   2-> c: puntero de la matriz c
   3-> referencia: puntero a la matriz que contiene los resultados comprobados (fueron calculados de forma escalar y usando tipo float para tener una mayor precision) */
static int verificar_resultado(size_t n, const float *c, const double *referencia)
{
	// Declaracion de variables
    size_t errores = 0;	// Contador del numero de errores
    double error_maximo = 0.0;	// Rastrea
    double checksum = 0.0;	// Acumulad

    // Revisar todos los elementos de la matriz de resultados.
    for (size_t p = 0; p < n * n; p++) {
        double obtenido = (double)c[p];	// Extrae el valor calculado por las instrucciones SVE (float de 32 bits) y lo convierte a un tipo double (64 bits) para poder comparar con la referencia
        double esperado = referencia[p];	// Extrae el valor calculado por las instrucciones SVE (float de 32 bits) y lo convierte a un tipo double (64 bits) para compararlo con la referencia

        // Detectar valores invalidos antes de calcular la diferencia
        if (!isfinite(obtenido) || !isfinite(esperado)) {
            errores++;	// Se actualiza el contador de errores
            error_maximo = INFINITY;	// El error maximo se actualiza a infinito
            continue;	// Continua con la siguiente iteracion
        }

		// fabs(): valor absoluto en punto flotante
        double error = fabs(obtenido - esperado);	// Se calcula la diferencia entre el valor del dato SVE vs el esperado

        // Usar la misma tolerancia que en el programa escalar
        double tolerancia = 1e-5 + 1e-5 * fabs(esperado);	// Algoritmo para la tolerancia (Tolerancia absoluta + tolerancia relativa)

		// SI la diferencia superar la tolerecnia se activa este IF
        if (error > tolerancia) {
            errores++;	// Se actualiza el contador de errores
        }

		// Si el error actual es mas grande en comparacion al error maximo registrado se activa este IF
        if (error > error_maximo) {
            error_maximo = error;	// Se actualiza el contador de error maximo con el error actual
        }

        checksum += obtenido;	// Se suma el valor obtenido al total general
    }

    // Mostrar el resultado de la comprobacion elemento por elemento.
    printf("N=%zu CHECK=%s errores=%zu " "max_abs_error=%.9g checksum=%.17g\n", n, errores == 0 ? "PASS" : "FAIL", errores, error_maximo, checksum);	// Imprimir en pantalla los datos estadisticos obtenidos

    return errores == 0 ? EXIT_SUCCESS : EXIT_FAILURE;	// Genera el codigo de salida para verificar el estado de la prueba
}

//----------------------------------------------------------------------------------------------------------

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

//=========================================================================================================================================

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

	// Este IF es para comprobar si existe memoria RAM disponible, si no existe memoria disponible las instrucciones malloc/calloc devuelven un NULL
    if (a == NULL || b == NULL || c == NULL || referencia == NULL) {
        fprintf(stderr, "Error al reservar memoria para las matrices.\n");	// Se imprime el error en pantalla
		// Si el IF se ejecuta por el error de memoria, se libera cualquier memoria dinamica que si haya tenido exito
        free(a);
        free(b);
        free(c);
        free(referencia);

        return EXIT_FAILURE;	// Genera el fallo
    }

	// Preparar las matrices antes de comenzar la medicion
    inicializar(n, a, b, c);

    /* Mostrar la longitud vectorial disponible
       Cada elemento float va a ocupar 32 bits */
    size_t elementos_vector = (size_t)svcntw();

    printf("SVE VL_BITS=%zu ELEMENTOS_FLOAT=%zu\n", elementos_vector * 32, elementos_vector);	// Imprimir en pantalla

#ifdef USE_GEM5
    // Descartar las estadisticas de preparacion del programa
    m5_reset_stats(0, 0);
#endif

    // Ejecutar la multiplicacion que se va a medir
    gemm_sve(n, a, b, c);

#ifdef USE_GEM5
    // Guardar las estadisticas de la multiplicacion
    m5_dump_stats(0, 0);
#endif

    /* Calcular la referencia despues de la medicion
       Esto con el fin de que este calculo de la referencia no forme parte de las estadisticas de GEMM SVE. */
    calcular_referencia(n, a, b, referencia);

    // Comparar todos los elementos y conservar el estado de la prueba
    int resultado = verificar_resultado(n, c, referencia);

    // Liberar la memoria reservada
    free(a);
    free(b);
    free(c);
    free(referencia);

    // Indicar si la comprobacion fue exitosa
    return resultado;
}
