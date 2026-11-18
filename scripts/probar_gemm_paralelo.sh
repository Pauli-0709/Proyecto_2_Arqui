#!/usr/bin/env bash

# Esta seccion va a detener el script ante algun posible error o variables que no estan definidas
set -euo pipefail

#------------------------------------------------------------------------------------------------------------
raiz=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) # Se busca la raiz del repositorio
cd "$raiz" # Usa la misma carpeta de trabajo al lanzar las pruebas
gem5=/opt/gem5 # Usa las herramientas de la imagen del equipo
simulador="$gem5/build/ARM_MESI/gem5.opt" # Selecciona el ejecutable del simulador gem5
configuracion="$gem5/configs/deprecated/example/se.py" # Selecciona el modo SE
biblioteca="$gem5/util/m5/build/arm64/out/libm5.a" # Localiza las operaciones de la ROI


test -x "$simulador" && test -f "$configuracion" && test -f "$biblioteca" || { # Comprueba el entorno si todo esta OK sino es asi, genera el mensaje
    echo "Entra al Docker con bash scripts/arm_env.sh y ejecuta este script desde /work." >&2 # Imprime mensaje de como entrar
    exit 1 # Termina si el entorno de gem5 no se pudo ejecutar
}


#--------------------------------------------------------------------------------------------------------------------------------------------
validaciones="$raiz/results/validation" # Se define la ruta de donde guardar los registros de validacion
mkdir -p "$validaciones" # Se genera la carpeta si hace falta
salida=$(mktemp -d "$validaciones/gemm_paralelo_n16.XXXXXX") # Se crea una carpeta nueva para cada una de las ejecuciones
ejecutables="$raiz/bin/${salida##*/}" # Se utiliza el mismo nombre de la corrida para guardar los binarios en la carpeta bin
mkdir -p "$ejecutables" # Se crea la carpeta de los binarios
echo "SALIDA=$salida" # Se muestra en pantalla donde quedan los registros

fuente=src/gemm_paralelo.c # Selecciona el programa que se va a probar (gemm_paralelo.c)
opciones=(-O2 -Wall -Wextra -Werror -fopenmp -fno-tree-vectorize -ffp-contract=off) # Comparte las opciones de compilacion
gcc "${opciones[@]}" "$fuente" -lm -o "$ejecutables/nativo" # Se commpila para la arquitectura del contenedor
arm=(-static -DUSE_GEM5 "-I$gem5/include") # Activa el enlace estatico y las marcas de la ROI
aarch64-linux-gnu-gcc "${opciones[@]}" "${arm[@]}" "$fuente" "$biblioteca" -lm -o "$ejecutables/arm" # Se compila para el simulador gem5.
file "$ejecutables/arm" # Muestra la arquitectura y el tipo de enlace del ejecutable


#-----------------------------------------------------------------------------------------------------------------------------------------
for hilos in 1 2 4 8; do # Este for prueba cada cantidad solicitada por E4
    corrida="$salida/hilos_$hilos" # Se separa las diversas salidas por su cantidad de hilos
    mkdir "$corrida" # Se prepara la carpeta de esta simulacion
    esperado="N=16 HILOS=$hilos HILOS_USADOS=$hilos CHECK=PASS errores=0" # Se define el resultado exacto que es esperado

    "$ejecutables/nativo" 16 "$hilos" | tee "$corrida/nativo.log" # Se ejecuta primero la prueba
    grep -Fxq "$esperado" "$corrida/nativo.log" # Se van a verificar las celdas y los hilos usados
    cpu=(--cpu-type=ArmO3CPU "--num-cpus=$hilos" --caches --l2cache --mem-size=512MiB) # Se simula un nucleo por cada hilo
    ajustes=(--param 'system.cpu[:].issueWidth=2' --param 'system.cpu[:].forwardComSize=256') # Se ajusta todos los nucleos de la prueba


    if ! "$simulador" -d "$corrida" "$configuracion" "${cpu[@]}" "${ajustes[@]}" -c "$ejecutables/arm" -o "16 $hilos" > "$corrida/run.log" 2>&1; then # Se ejecuta la prueba en ARM
        tail -n 30 "$corrida/run.log" >&2 # Muestra el final del registro si falla el simulador gem5
        exit 1 # Detiene la prueba en la primera configuracion que se identifico el fallo
    fi

    grep -Fx "$esperado" "$corrida/run.log" # Se debe confirmar que el programa ARM valido las celdas y los hilos correspondientes
    bloques=$(grep -c 'End Simulation Statistics' "$corrida/stats.txt") # Se cuentan los bloques completos del simulador gem5


    if (( bloques < 2 )); then # Espera el volcado de la ROI y el volcado final
        echo "Faltan bloques de estadisticas en $corrida/stats.txt" >&2 # Mensaje para indicar que archivo a revisar
        exit 1 # Detiene la validacion si falta un bloque
    fi



done # Termina las pruebas con la configuracion de 1, 2, 4 y 8 hilos

echo "VALIDACION_PARALELA_OK N=16 CORRIDAS_GEM5=4" # Mensaje para confirmar que pasaron todas las pruebas
