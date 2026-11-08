//Inclusion de la bibliotecas necesarias
#include <stdio.h>  //Biblioteca que tiene funciones de entrada/salida estandar (printf y fprintf)
#include <stdlib.h> //Biblioteca que tiene funciones de gestion de memoria dinamica (malloc, calloc y free) y la conversion de cadenas (strtoul)
#include <errno.h>  //Biblioteca que permite capturar codigos de error del sistema
#include <math.h>   //Biblioteca que tiene funciones matemeticas como fabs (valor absoluto) y isfinite (verificar si un numero es valido)

//Directiva de preprocesamiento, esta va a comprobar si la macro denominada USE_GEM5 ha sido definida correctamente
//Esto tambien permite que el mismo codigo fuente funcione tanto en un equipo real como en el simulador de gem5
#ifdef USE_GEM5
#include <gem5/m5ops.h>	//Incluye el archivo de cabera oficial del simulador de gem5 el cual declara las llamadas a funciones especiales
#endif	//Fin del condicional para la instruccion USE_GEM5

//-------------------------------------------------------------------------------------------------------------------------------
//Inicializa las distintas matrices. Asimismo, las matrices se almacenan por filas en los diversos arreglos continuos
static void inicializar(size_t n, float *a, float *b, float *c)
{
	//Bucle externo: el objetivo es el poder recorrer cada fila (i) de la matriz de tamano n x n
    for (size_t i = 0; i < n; i++) {
       //Bucle inerno: el objetivo es el de poder recorrer cada columna (j) de la matriz
        for (size_t j = 0; j < n; j++) {
            size_t posicion = i * n + j;	//Calculo del indice equivalente a la coordenada (i, j)
            int valor_a = (int)((17 * i + 13 * j + 1) % 31) - 15;	//Valores random pero fijos para a, esto con el fin de que no cambien en cada ejecucion
            int valor_b = (int)((7 * i + 19 * j + 3) % 29) - 14;	//Valores random pero fijos para b, esto con el fin de que no cambien en cada ejecucion

            a[posicion] = (float)valor_a / 16.0f;	//Convierte a tipo float, escala dividiendo entre 16.0 y asigna el valor a la matriz a
            b[posicion] = (float)valor_b / 16.0f;	//Convierte a tipo float, escala dividiendo entre 16.0 y asigna el valor a la matriz b
		    c[posicion] = 0.0f;	//Inicializa la matriz de resultados denominada c y la llena con ceros (0) en cada una de las posiciones
		}
    }
}
//----------------------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------------
//Multiplicacion escalar C = A * B.
//Orden de bucles: i-j-k y la acumulacion se realiza en precision simple.
__attribute__((noinline))		//Forzar a que la función no se expanda sola (noinline) para que la misma aparezca bien en el gdb/perf

//Función gemm_scalar, esta tiene como objetivo el poder realizar la multiplicacion de matrices en tamaño n
void gemm_scalar(size_t n, const float *a, const float *b, float *c)
{
	//Bucle i: este tiene como objetivo recorrer cada fila de la matriz A y de la matriz C
    for (size_t i = 0; i < n; i++) {
    	// Bucle j: este tiene como objetivo el recorrer cada columna de la matriz B y de la matriz C
        for (size_t j = 0; j < n; j++) {
            float suma = 0.0f; //Variable para acumular la suma del producto punto, utilizando precision simple. Ademas se iniciliaza en 0.0
			// Bucle k: este tiene como objetivo el recorrer los elementos a lo largo de la fila de A y la columna de B
            for (size_t k = 0; k < n; k++) {
                suma += a[i * n + k] * b[k * n + j];	//Multiplica el elemento de la matriz A por el elemento de la matriz B y lo suma y lo coloca en la variable suma
            }

            c[i * n + j] = suma;	//Se le asigna la suma acumulada final a la celda correspondiente (i, j) de la matriz C
        }
    }
}
//Fin de la funcion gemm_scalar
//-----------------------------------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------------------------------------
//Funcion verificar, esta tiene como objetivo verificar los resultados obtenidos
static int verificar(size_t n, const float *a, const float *b, const float *c, double *referencia)
{
	//Primer bucle con la variable j (siguiendo el orden j-k-i): tiene como objetivo el recorrer las columnas
    for (size_t j = 0; j < n; j++) {
    	//Segundo bucle con la variable k: tiene como objetivo el de recorrer los índices intermedios
        for (size_t k = 0; k < n; k++) {
			//Tercer bucle con la variable i: este tiene como objetivoel de recorrer las filas
            for (size_t i = 0; i < n; i++) {
                referencia[i * n + j] += (double)a[i * n + k] *(double)b[k * n + j]; //Asigna la suma de los diversos productos
            }
        }
    }

    size_t errores = 0;	//Inicializar el contador de errores encontrados en 0
    double error_maximo = 0.0;	//Inicializa la variable (0.0) para buscar un posible error absoluto maximo
    double checksum = 0.0;	//Inicializa la variable en 0.0

	//Tiene como objetivo el recorrer todos los elementos para comparar el resultado frente a la variable referencia
    for (size_t p = 0; p < n * n; p++) {
        double obtenido = (double)c[p];	//Convierte de tipo float a tipo double
        double error = fabs(obtenido - referencia[p]);	//Calcula el valor absoluto de la diferencia entre el valor obtenido vs el de referencia
        double tolerancia = 1e-5 + 1e-5 * fabs(referencia[p]); //Se define una tolerancia para aceptar las distintas pequeñas variaciones que se pueden dar por el redondeo numérico

       	//Se comprueba si el valor especifico en analisis es finito o no o si el mismo llega a exceder la tolerancia dada en la linea anterior, y se suma al contador
        if (!isfinite(obtenido) || error > tolerancia) {
            errores++;
        }

		//Se registra el error absoluto maximo encontrado
        if (error > error_maximo) {
            error_maximo = error;
        }

        checksum += obtenido;	//Acumula la suma total en la variable checksum de los distintos valores obtenidos
    }

	//Imprime en consola un informe detallado del estado de la validacion que se ejecuto
    printf("N=%zu CHECK=%s errores=%zu " "max_abs_error=%.9g checksum=%.17g\n", n, errores == 0 ? "PASS" : "FAIL", errores, error_maximo, checksum);

    return errores == 0 ? EXIT_SUCCESS : EXIT_FAILURE;	//Va a retornar dos opciones: si es exito (0) si no hay errores, o si es un fallo (1) en caso contrario
}
//Fin de la funcion de verificar
//------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------
//Funcion principal, esta tiene como objetivo recibir los argumentos de la línea de comandos
int main(int argc, char *argv[])
{
	//El if va a validar que se reciba un argumento por consola y que el mismo comience con un digito numerico
    if (argc != 2 || argv[1][0] < '0' || argv[1][0] > '9') {
        fprintf(stderr, "Uso: %s N, con N entre 1 y 1024\n", argv[0]);	//Imprimir un mensaje de error
        return EXIT_FAILURE;	//Retorna un codigo de error de fallo en la ejecucion, si el if se ejecuta
    }

    errno = 0;	//Reinicia la variable errno a 0
    char *fin = NULL; //Se declara un puntero auxiliar denominado fin con el objetivo de detectar caracteres sobrantes en la conversion
    unsigned long valor = strtoul(argv[1], &fin, 10);	//Convierte la cadena de texto en cuestion del argumento 1 a un numero entero (base 10)

	//Va a valirdar que no ocurran desbordamientos, que la conversión sea correcta y que el N este o se encuentre entre 1 y 1024
    if (errno != 0 || *fin != '\0' || valor < 1 || valor > 1024) {
        fprintf(stderr, "Error: N debe ser un entero entre 1 y 1024.\n");	//Imprime un mensaje de error en stderr
        return EXIT_FAILURE;	//Retorna un codigo de error de fallo en la ejecucion, si el if se ejecuta
    }

    size_t n = (size_t)valor;	//Convierte el valor a un tipo size_t para poder representar el tamano n
    size_t elementos = n * n;	//Va a calcular el numero total de elementos de la matriz cuadrada (n * n)
    float *a = malloc(elementos * sizeof(*a));	//Va a reservar memoria dinamica en el heap-almacen para la matriz a de tipo float
    float *b = malloc(elementos * sizeof(*b));	//Va a reservar memoria dinamica en el heap-almacen para la matriz b de tipo float
    float *c = malloc(elementos * sizeof(*c));	//Va a reservar memoria dinamica en el heap-almacen para la matriz c de tipo float -> MATRIZ RESULTADOS
    double *referencia =  calloc(elementos, sizeof(*referencia));	//Declaracion del puntero referencia de tipo double y va a reservar memoria dinamica inicializada en 0 en el heap-almacen para la matriz de referencia

	//Va a comprobar si alguna de las reservas de memoria dinámicas fallo o no funciono
    if (a == NULL || b == NULL || c == NULL || referencia == NULL) {
        fprintf(stderr, "Error al reservar memoria.\n");	//Imprime en pantallao el fallo de asignacion de memoria
        free(a);	//Libera la memoria asignada a la matriz a
        free(b);	//Libera la memoria asignada a la matriz b
        free(c);	//Libera la memoria asignada a la matriz c
        free(referencia);	//Libera la memoria asignada a la matriz referencia
        return EXIT_FAILURE;	//Retorna un codigo de error de fallo, este si se da es por falta de memoria.
    }

	//Llamado de las subfunciones
	//Parametros: n-> dimension de las matrices, a-> primer matriz de entrada, b-> segunda matriz de entrada, c-> matriz de resultados y referencia -> matriz de validacion 
    inicializar(n, a, b, c);	//Llama a la subfuncion inicializar y le da los parametros

#ifdef USE_GEM5
    m5_reset_stats(0, 0);	//Reinicia las estadisticas del simulador gem5 en este punto exacto. Esto es importante porque descarta todo el coste de inicializacion como lo es la asignacion de memoria, entre otros. 
#endif

    gemm_scalar(n, a, b, c);	//Llama a la subfuncion gemm_scalar y le da los parametros. Asimismo, es importante indicar que esto es lo que interesa medir

#ifdef USE_GEM5
    m5_dump_stats(0, 0);	//Guarda las estadisticas acumuladas en el simulador gem5 al archivo de salida (stats.txt). A su vez, estas estadisticas reflejan unicamente el rendimiento real de gemm_scalar gracia al reset previo
#endif

    int resultado = verificar(n, a, b, c, referencia); //Va a comprobar y validar los resultados obtenidos vs a la referencia
    free(a);	//Libera la memoria asignada a la matriz a
    free(b);	//Libera la memoria asignada a la matriz b
    free(c);	//Libera la memoria asignada a la matriz c
    free(referencia);	//Libera la memoria asignada a la matriz referencia
    return resultado;	//Retorna el codigo  de resultado final del programa
}
//Fin de la funcion main
//----------------------------------------------------------------------------------------------------------------------------------=
