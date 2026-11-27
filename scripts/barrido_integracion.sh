#!/usr/bin/env bash
# E6: corre todas las configuraciones del CSV con un N dado.
# Uso (dentro del entorno ARM): bash scripts/barrido_integracion.sh N
# Variables: SOLO="id1 id2" (subconjunto), PARALELO=2 (corridas simultaneas), CSV=...
set -euo pipefail

RAIZ=$(cd -- "$(dirname -- "$0")/.." && pwd)
cd "$RAIZ"
source scripts/lib_evidencia.sh

N=${1:?Uso: bash scripts/barrido_integracion.sh N}
CSV=${CSV:-configs/e6_configuraciones.csv}
SALIDA=${SALIDA:-results/e6/n$N}
SOLO=${SOLO:-}
PARALELO=${PARALELO:-2}
GEM5=${GEM5_BIN:-$GEM5_DIR/build/ARM_MESI/gem5.opt}
BIN=${BIN:-bin/e6/gemm_paralelo_sve_arm}
ETAPAS=(fetchWidth decodeWidth renameWidth dispatchWidth issueWidth wbWidth commitWidth)

GEM5_BIN="$GEM5" verificar_entorno
python3 scripts/modelo_costo.py --validar "$CSV" "${PRESUPUESTO:-32}" > /dev/null

mkdir -p "$SALIDA" "$(dirname "$BIN")" .local
exec 9>.local/e6.lock
flock -n 9 || error "ya hay una corrida de E6 en este clon"

# Un solo binario sirve para todas las configuraciones: el VL se fija con --param.
compilar_arm src/gemm_paralelo_sve.c "$BIN" "$SALIDA/compilacion" \
    -std=c11 -O2 -Wall -Wextra -Werror -fopenmp \
    -fno-tree-vectorize -fno-tree-slp-vectorize -ffp-contract=off \
    -march=armv8-a+sve -msve-vector-bits=scalable ${EXTRA_CFLAGS:-}

# Comprueba que el kernel contiene instrucciones SVE (la libc estatica trae las suyas).
aarch64-linux-gnu-objdump -d "$BIN" \
    | awk '/^[0-9a-f]+ <.*(fila_sve|gemm_sve_omp).*>:/{p=1;print;next} /^$/{p=0} p' \
    > "$SALIDA/compilacion/kernel_sve_asm.txt"
grep -Eq 'fmul[[:space:]]+z[0-9]+\.s' "$SALIDA/compilacion/kernel_sve_asm.txt" \
    || error "el kernel no contiene fmul SVE"
grep -Eq 'fadd[[:space:]]+z[0-9]+\.s' "$SALIDA/compilacion/kernel_sve_asm.txt" \
    || error "el kernel no contiene fadd SVE"

correr() {
    local id=$1 nucleos=$2 ancho=$3 vl=$4 dir="$SALIDA/$1" codigo=0
    local esperado="N=$N HILOS=$nucleos HILOS_USADOS=$nucleos CHECK=PASS errores=0"

    if [[ -f $dir/validation.txt ]] && head -n1 "$dir/validation.txt" | grep -qx 'estado=PASS'; then
        printf 'OMITIDA (ya valida) %s\n' "$dir"
        return 0
    fi
    rm -rf "$dir"; mkdir -p "$dir"

    local comando=("$GEM5" -d "$dir" "$SE_PY"
        --cpu-type=ArmO3CPU "--num-cpus=$nucleos"
        --cpu-clock=2GHz --sys-clock=1GHz --caches --l2cache
        --l1i_size=32KiB --l1d_size=32KiB --l2_size=256KiB
        --l1i_assoc=2 --l1d_assoc=2 --l2_assoc=8
        --cacheline_size=64 --mem-type=DDR3_1600_8x8 --mem-size=512MiB)
    local etapa
    for etapa in "${ETAPAS[@]}"; do
        comando+=(--param "system.cpu[:].$etapa=$ancho")
    done
    comando+=(--param "system.cpu[:].numROBEntries=192"
              --param "system.cpu[:].numIQEntries=64"
              --param "system.cpu[:].forwardComSize=256"
              --param "system.cpu[:].isa[:].sve_vl_se=$((vl / 128))"
              -c "$RAIZ/$BIN" -o "$N $nucleos")

    printf 'CORRIDA %s (N=%s nucleos=%s ancho=%s VL=%s)\n' "$id" "$N" "$nucleos" "$ancho" "$vl"
    { printf '%q' "${comando[0]}"; printf ' %q' "${comando[@]:1}"; printf '\n'; } > "$dir/command.txt"
    "${comando[@]}" > "$dir/run.log" 2>&1 || codigo=$?
    printf '%s\n' "$codigo" > "$dir/exit_code.txt"
    if ! validar_corrida "$dir" "$esperado"; then
        tail -n 25 "$dir/run.log" >&2
        error "corrida invalida: $dir"
    fi
}

activos=0
while IFS=, read -r id nucleos ancho vl _justificacion; do
    if [[ -n $SOLO && " $SOLO " != *" $id "* ]]; then
        continue
    fi
    correr "$id" "$nucleos" "$ancho" "$vl" &
    activos=$((activos + 1))
    if (( activos >= PARALELO )); then
        wait -n
        activos=$((activos - 1))
    fi
done < <(tail -n +2 "$CSV")
wait

printf 'BARRIDO_E6_OK N=%s SALIDA=%s\n' "$N" "$SALIDA"
