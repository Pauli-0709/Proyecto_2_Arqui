#!/usr/bin/env bash

# Detiene el script por si falla un comando o falta alguna variable.
set -euo pipefail

#------------------------------------------------------------------------

# Encuentra la raiz del repositorio a partir del archivo
RAIZ=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

# Entra a la raiz del repositorio
cd "$RAIZ"

# Carga las herramientas necesarias y las opciones de memoria
source scripts/lib_evidencia.sh

#------------------------------------------------------------------------------

# Pide un modo y una carpeta de salida nueva.
[[ $# == 2 ]] || error "Uso: $0 prueba|barrido carpeta_nueva"

# Escoge los tamanos que se van a probar.
case "$1" in
    prueba) tamanos=(16) ;;       # Prueba corta en los tres modelos.
    barrido) tamanos=(64 128) ;;  # Seis corridas del experiemento E1.
    *) error "Usa prueba o barrido." ;;
esac



# Guarda la carpeta solicitada
salida=$2

# Confirma que el simulador, el se.py y el compilador estan disponibles.
verificar_entorno

# Prepara la carpeta y los ejecutables.
mkdir -p -- "$(dirname -- "$salida")" bin

# Crea la carpeta y protege los resultados anteriores.
mkdir -- "$salida"

# Registra la version del entorno que se utiliza.
registrar_entorno "$salida"

# Reserva una carpeta para el ejecutable.
carpeta_bin=$(mktemp -d "$RAIZ/bin/e1.XXXXXX")

# Va a utilizar el mismo ejecutable para todos los modelos.
binario="$carpeta_bin/gemm_escalar"

# Usa la config C11 y O2, desactiva la vectorizacion y conserva las operaciones en forma separadas.
opciones_c=(-std=c11 -O2 -fno-tree-vectorize -fno-tree-slp-vectorize -ffp-contract=off)

# sE Compila para el ARM con el enlace estatico y guarda el comando.
compilar_arm src/gemm_scalar.c "$binario" "$salida" "${opciones_c[@]}"

# Guarda el ensamblado de la multiplicacion para revisar que sea escalar su codigo.
"$OBJDUMP_ARM" -d --disassemble=gemm_scalar "$binario" > "$salida/kernel_asm.txt"


#-------------------------------------------
#-------------------------------------------
# Recorre los tamanos elegidos.
for n in "${tamanos[@]}"; do

    # Recorre los 3 modelos de ARM del enunciado del proyecto.
    for cpu in ArmTimingSimpleCPU ArmMinorCPU ArmO3CPU; do

        # Elige un nombre de carpeta para el modelo en especifico.
        case "$cpu" in
            ArmTimingSimpleCPU) nombre=temporizado ;;
            ArmMinorCPU) nombre=minor ;;
            ArmO3CPU) nombre=fuera_de_orden ;;
        esac

        # Separa la evidencia por el tamano y el modelo en especifico.
        corrida="$salida/n$n/$nombre"

        # Crea la carpeta de la corrida.
        mkdir -p -- "$corrida"

        # Selecciona un solo nucleo del modelo que toca en la prueba.
        comando=("$GEM5_BIN" -d "$corrida" "$SE_PY" --cpu-type="$cpu" --num-cpus=1)

        # Agregar la misma memoria, el ejecutable y el valor del tamano N.
        comando+=("${OPCIONES_SISTEMA[@]}" -c "$binario" -o "$n")

        # Guarda el comando exacto para poder revisarlo despues.
        printf '%q ' "${comando[@]}" > "$corrida/comando.txt"

        # Termina la linea del comando guardado.
        printf '\n' >> "$corrida/comando.txt"

        # Muestra el modelo y el tamano que se estan ejecutando en la prueba.
        printf 'Probando %s con N=%s\n' "$cpu" "$n"

        # Ejecuta el simulador gem5 y guarda sus respectivas mensajes.
        "${comando[@]}" < /dev/null > "$corrida/run.log" 2>&1 ||
            error "gem5 fallo. Revisa $corrida/run.log"

        # Confirma que el producto de matrices coincide con la referencia ejecutada.
        grep -E -m1 "^N=$n CHECK=PASS errores=0( |$)" "$corrida/run.log" > "$corrida/validacion.txt" ||
            error "La comprobacion de GEMM fallo. Revisa $corrida/run.log"


        # Confirma que el simulador gem5 guardo correctamente la configuracion y las estadisticas respectivas.
        [[ -s "$corrida/config.ini" && -s "$corrida/stats.txt" ]] ||
            error "Falta config.ini o stats.txt en $corrida"


        # Exige un bloque para la ROI y otro al final del programa.
        [[ $(grep -c 'End Simulation Statistics' "$corrida/stats.txt") == 2 ]] ||
            error "Se esperaban dos bloques de estadisticas en $corrida"
    done
done



# Muestra donde quedaron las corridas comprobadas en la pantalla.
printf 'Corridas validadas en %s\n' "$salida"
