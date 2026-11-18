// Bibliotecas
#include <errno.h>    // Detecta los diversos errores al momento de convertir los argumentos
#include <inttypes.h> // Declara la instruccion PRIu64 para imprimir los distintos contadores
#include <omp.h>      // Declara las funciones para trabajar con hilos
#include <stdio.h>    // Declara las instruccion printf y fprintf
#include <stdlib.h>   // Declara la instruccion strtol y los codigos de salida
#include <string.h>   // Declara la instruccion strcmp para poder elegir el modo

#ifdef USE_GEM5 // Habilita las diversas marcas al momento de compilar para el simulador gem5
#include <gem5/m5ops.h> // Declara las operaciones de estadisticas de gem5
#endif // Termina la inclusion del simulador gem5

//-----------------------------------------------------------------------------------------------------------------------------------

enum { LINEA = 64, MAX_HILOS = 8, PASO = LINEA / sizeof(uint64_t) }; // Esta linea va a definir la linea y el espacio entre contadores
_Alignas(LINEA) static volatile uint64_t contadores[MAX_HILOS * PASO]; // Alinea el arreglo y conserva cada lectura y escritura.

// Funcion auxiliar - leer_entero
// Objetivo: leer un argumento dentro del rango
static long leer_entero(const char *texto, long minimo, long maximo){
    char *fin; // Variable que indica donde termino la conversion
    errno = 0; // Variable para va a limpia el estaddo de error antes de iniciar su conversion
    long valor = strtol(texto, &fin, 10); // Variable que convierte el argumento a un entero decimal

    if (errno != 0 || fin == texto || *fin != '\0' || valor < minimo || valor > maximo) { // Verificacion para rechazar entradas invalidas
        return 0; // Se devuelve un 0 para indicar el error en la verificacion
    }
    return valor; // Se devuelve el entero validado y que esta correcto
}


// --------------------------------------------------------------------------------------------------------------------------
// Funcion principal
// Esta funcion va a recibir la cantidad de hilos, el modo (que se requiere) y las iteraciones opciones
int main(int argc, char *argv[]){

    if (argc != 3 && argc != 4) { // Comprobacion de argumentos: verifica que existan 2 argumentos
        fprintf(stderr, "Uso: %s HILOS sin_relleno|con_relleno [ITERACIONES]\n", argv[0]); // Mensaje en pantalla del error y muestra el formatos correcto
        return EXIT_FAILURE; // Finaliza el programa por el uso incorrecto
    }

	// Declaracion de variables
    int hilos = (int)leer_entero(argv[1], 2, MAX_HILOS); // acepta entre 2 y 8 hilos
    long iteraciones = argc == 4 ? leer_entero(argv[3], 1, 100000000) : 100000; // 100 000 incrementos por defecto
    int paso = strcmp(argv[2], "sin_relleno") == 0 ? 1 : 0; // usa contadores contiguos en el primer modo



    if (strcmp(argv[2], "con_relleno") == 0) { // If para comprobar que si se pidio el segundo modo
        paso = PASO; // Se actualiza variable para separar los contadores por 64 bytes
    }


    if (hilos == 0 || iteraciones == 0 || paso == 0) { // If para comporbar que los argumentos antes de iniciar los diversos hilos
        fprintf(stderr, "Error: revise HILOS, MODO e ITERACIONES.\n"); // Mensaje en pantalla para informar que existe un argumento invalido
        return EXIT_FAILURE; // Termina la ejecucion por un uso incorrecto
    }


    int hilos_usados = 0; // Variable que guarda cuantos hilos creo OpenMP
    omp_set_dynamic(0); // Se solicita el numero indicado de hilos

    #pragma omp parallel num_threads(hilos) //Instruccion que crea el equipo antes de iniciar con la medicion
    {
        int indice = omp_get_thread_num() * paso; // Variable que asigna un contador distinto a cada hilo
        #pragma omp barrier // Instruccion que espera a que todos los hilos esten listos
        #pragma omp master // Instruccion que inicial la medicion en el hilo prinicipal
        {
            hilos_usados = omp_get_num_threads(); // Variable que registra el total real de hilos

#ifdef USE_GEM5 // Instruccion en el simulador gem5 que reinicia los contadores del simulador
            m5_reset_stats(0, 0); // Apertura de la region de interes
#endif // Termina la marca de inicio
        }



        #pragma omp barrier // Instruccion para liberar los hilos despues del inicio de la medicion

        for (long i = 0; i < iteraciones; i++) { // For para repetir el mismo trabajo en ambos modos
            contadores[indice]++; // Variable que lee y actualiza el contador propio de este hilo en especifico
        }

        #pragma omp barrier // Instruccion que espera a que todos los contadores esten completos
        #pragma omp master // Instruccion para cerrar la medicion en el hilo principal

        {
#ifdef USE_GEM5 // Instruccion del simulador gem5 que guarda los contadores del simulador
            m5_dump_stats(0, 0); // Cierra la region de interes y vuelca las estadisticas
#endif
        }
    } // Cierre de linea 64

    int errores = 0; // Variable que cuenta los contadores con un valor incorrecto

    for (int hilo = 0; hilo < hilos; hilo++) { // For que comprueba el contador de cada hilo solicitado
        if (contadores[hilo * paso] != (uint64_t)iteraciones) { // Condicional para comparar con el numero esperado de incrementos
            errores++; // Se actualiza el contador
        }
    }


    uint64_t esperado = (uint64_t)hilos * (uint64_t)iteraciones; // Se calcula el total esperado
    int correcto = errores == 0 && hilos_usados == hilos; // Se exige los valores correctos y todos los hilos
    printf("HILOS=%d HILOS_USADOS=%d MODO=%s ITERACIONES=%ld ESPERADO=%" PRIu64 " CHECK=%s errores=%d\n", hilos, hilos_usados, argv[2], iteraciones, esperado, correcto ? "PASS" : "FAIL", errores); // Se imprime en pantalla la comprobacion final

	#ifdef USE_GEM5 // Instruccion que termina la simulacion despues de validar los contadores
    if (fflush(stdout) == EOF || !correcto) { // If que escribe el resultado antes de avisar al simulador gem5
        m5_fail(0, EXIT_FAILURE); // Finaliza la simulacion con el error
    } else {
        m5_exit(0); // Finaliza el simulador gem5
    }
	#endif

    return correcto ? EXIT_SUCCESS : EXIT_FAILURE; // Informa al script si paso la prueba o no
}
