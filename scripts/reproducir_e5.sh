#!/usr/bin/env bash
# Ejecuta el experimento E5 desde la compilacion hasta los archivos CSV, los graficos y el resumen correspondiente.
set -euo pipefail # Detiene el script si falla un paso.


#==========================================================================

RAIZ=$(cd -- "$(dirname -- "$0")/.." && pwd) # Encuentra la raiz del repositorio.
cd "$RAIZ" # Usa la misma ruta de trabajo en todas las corridas que se ejecuten.
source scripts/lib_evidencia.sh # Reutiliza la compilacion y la validacion del equipo.

if (( $# > 1 )) || [[ $# == 1 && ${1:-} != --piloto ]]; then
    error "Uso: bash scripts/reproducir_e5.sh [--piloto]"
fi

protocolos=(MESI MOESI) # Usa los 2 ejecutables Ruby de la imagen.
modos=(con_relleno sin_relleno) # Separa o junta los contadores en la cache.
iteraciones=100000 # Fija el mismo trabajo por cada uno de los hilos en todo el barrido.



for protocolo in "${protocolos[@]}"; do
    GEM5_BIN="$GEM5_DIR/build/ARM_$protocolo/gem5.opt" verificar_entorno
done
command -v gcc >/dev/null || error "falta gcc para las pruebas nativas"
python3 -c 'import matplotlib' # Comprueba las graficas.



mkdir -p .local bin # Prepara las carpetas de trabajo local para guardar la corrida.
salida=$(mktemp -d .local/e5.XXXXXX) # Crea una salida nueva para cada una de las ejecuciones.

# Evita que 2 ejecuciones escriban sobre los mismos binarios al mismo tiempo.
exec 9>.local/e5_reproducible.lock
flock -n 9 || error "ya hay una ejecucion de E5 en este clon"

# Usa la misma ruta de los binarios dentro del Docker en todas las corridas.
binarios="bin/e5_reproducible"
mkdir -p "$binarios"

printf 'SALIDA_E5=%s\n' "$salida" # Muestra la ruta en pantalla.



for protocolo in "${protocolos[@]}"; do
    GEM5_BIN="$GEM5_DIR/build/ARM_$protocolo/gem5.opt" \
        registrar_entorno "$salida/entorno/$protocolo" # Registra la version y el hash correspondiente.
done


opciones=(-O2 -Wall -Wextra -Werror -fopenmp) # Comparte opciones entre los diferentes binarios.
gemm=(-fno-tree-vectorize -ffp-contract=off) # Mantiene el GEMM escalar por filas.



gcc "${opciones[@]}" -std=c11 src/falso_compartido.c -o "$binarios/falso_nativo"
gcc "${opciones[@]}" "${gemm[@]}" src/gemm_paralelo.c -lm -o "$binarios/gemm_nativo"
compilar_arm src/falso_compartido.c "$binarios/falso_arm" \
    "$salida/compilacion/falso_compartido" "${opciones[@]}" -std=c11
compilar_arm src/gemm_paralelo.c "$binarios/gemm_arm" \
    "$salida/compilacion/gemm" "${opciones[@]}" "${gemm[@]}" -DE5_RUBY




# Prepara las lineas que deben imprimir los programas al validar el resultado correspondiente.
esperado_falso() {
    printf 'HILOS=%s HILOS_USADOS=%s MODO=%s ITERACIONES=%s ESPERADO=%s CHECK=PASS errores=0' \
        "$1" "$1" "$2" "$3" "$(($1 * $3))"
}

esperado_gemm() {
    printf 'N=%s HILOS=%s HILOS_USADOS=%s CHECK=PASS errores=0' "$1" "$2" "$2"
}




# Guarda la salida de una prueba nativa y exige el resultado esperado.
probar_nativo() {
    local log=$1 esperado=$2
    shift 2
    "$@" > "$log" 2>&1 || error "fallo la prueba nativa: $log"
    grep -Fxq -- "$esperado" "$log" || error "validacion nativa incorrecta: $log"
}



# Ejecuta una corrida de Ruby en una carpeta nueva y valida su evidencia correspondientes.
simular() {
    local protocolo=$1 dir=$2 hilos=$3 binario=$4 argumentos=$5 esperado=$6 # Recibe los datos de un caso en especifico.
    local codigo=0 # Conserva el codigo real de salida del simulador.
    local comando=("$GEM5_DIR/build/ARM_$protocolo/gem5.opt" -d "$dir" "$SE_PY"
        --ruby --cpu-type=ArmTimingSimpleCPU "--num-cpus=$hilos"
        --cacheline_size=64 --mem-size=512MiB -c "$RAIZ/$binario" -o "$argumentos")

    mkdir -p "$dir" # Prepara la carpeta de esta configuracion en particular.
    printf 'CORRIDA %s\n' "$dir" # Muestra en pantalla que caso se esta ejecutando la prueba.


    # Guarda el comando con sus argumentos tal como se ejecuto.
    { printf '%q' "${comando[0]}"; printf ' %q' "${comando[@]:1}"; printf '\n'; } > "$dir/command.txt"
    "${comando[@]}" > "$dir/run.log" 2>&1 || codigo=$?
    printf '%s\n' "$codigo" > "$dir/exit_code.txt"
    if ! validar_corrida "$dir" "$esperado"; then
        tail -n 25 "$dir/run.log" >&2
        error "corrida invalida: $dir"
    fi
    if ! grep -Fq 'because m5_exit instruction encountered' "$dir/run.log"; then
        printf 'estado=FAIL\nmotivo=falta la salida con m5_exit\n' > "$dir/validation.txt"
        error "falta la salida con m5_exit: $dir"
    fi
}




mkdir -p "$salida/validacion/nativa"

for hilos in {2..8}; do # Valida todas las cantidades de hilos del barrido correspondiente.
    for modo in "${modos[@]}"; do
        probar_nativo "$salida/validacion/nativa/falso_h${hilos}_$modo.log" \
            "$(esperado_falso "$hilos" "$modo" 1000)" "$binarios/falso_nativo" "$hilos" "$modo" 1000
    done
    probar_nativo "$salida/validacion/nativa/gemm_h$hilos.log" \
        "$(esperado_gemm 16 "$hilos")" "$binarios/gemm_nativo" 16 "$hilos"
done



for protocolo in "${protocolos[@]}"; do # Prueba ambos programas con Ruby antes del barrido completo.
    for modo in "${modos[@]}"; do
        simular "$protocolo" "$salida/validacion/${protocolo}_falso_$modo" 2 \
            "$binarios/falso_arm" "2 $modo 1000" "$(esperado_falso 2 "$modo" 1000)"
    done
    simular "$protocolo" "$salida/validacion/${protocolo}_gemm_n16" 2 \
        "$binarios/gemm_arm" "16 2" "$(esperado_gemm 16 2)"
done
printf 'VALIDACION_E5_OK NATIVAS=21 RUBY=6 SALIDA=%s\n' "$salida"
if [[ ${1:-} == --piloto ]]; then
    exit 0
fi



for protocolo in "${protocolos[@]}"; do # Barre los 2 protocolos completos.
    for hilos in {2..8}; do # Usa un nucleo simulado por cada uno de los hilos.
        for modo in "${modos[@]}"; do # Genera las 28 corridas de falso compartido.
            simular "$protocolo" "$salida/falso_compartido/${protocolo}_h${hilos}_$modo" "$hilos" \
                "$binarios/falso_arm" "$hilos $modo $iteraciones" \
                "$(esperado_falso "$hilos" "$modo" "$iteraciones")"
        done


        for n in 64 128; do # Genera las 28 corridas de GEMM paralelo.
            simular "$protocolo" "$salida/gemm/${protocolo}_n${n}_h$hilos" "$hilos" \
                "$binarios/gemm_arm" "$n $hilos" "$(esperado_gemm "$n" "$hilos")"
        done
    done
done



python3 scripts/analizar_e5.py "$salida" # Lee solo las corridas nuevas de esta ejecucion en especifico.
printf 'REPRODUCCION_E5_OK CORRIDAS=56 CSV=3 FIGURAS=4 SALIDA=%s\n' "$salida"
