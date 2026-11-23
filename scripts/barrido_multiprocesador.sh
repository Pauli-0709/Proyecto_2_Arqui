#!/usr/bin/env bash
# E4: O3 de ancho fijo, GEMM paralelo por filas con 1/2/4/8 nucleos (N = 64 y 128).
# Uso: bash scripts/arm_env.sh env PARALELO=3 bash scripts/barrido_multiprocesador.sh
# Variables: TAMANOS NUCLEOS ANCHO ETAPAS ROB FORWARD_COM PARALELO SALIDA FUENTE MEM
set -euo pipefail
RAIZ=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd); cd "$RAIZ"
source "$RAIZ/scripts/lib_evidencia.sh"

TAMANOS=${TAMANOS:-"64 128"}
NUCLEOS=${NUCLEOS:-"1 2 4 8"}
ANCHO=${ANCHO:-2}
ETAPAS=${ETAPAS:-"fetchWidth decodeWidth renameWidth dispatchWidth issueWidth wbWidth commitWidth"}
ROB=${ROB:-192}
IQ=${IQ:-64}
FORWARD_COM=${FORWARD_COM:-256}
PARALELO=${PARALELO:-2}
SALIDA=${SALIDA:-$RAIZ/results/e4}
FUENTE=${FUENTE:-$RAIZ/src/gemm_paralelo.c}
BINARIO=$RAIZ/bin/e4/arm

verificar_entorno
[[ -f $FUENTE ]] || error "no existe $FUENTE"

PARAMS=(--param "system.cpu[:].forwardComSize=$FORWARD_COM"
        --param "system.cpu[:].numIQEntries=$IQ"
        --param "system.cpu[:].numROBEntries=$ROB")
for etapa in $ETAPAS; do PARAMS+=(--param "system.cpu[:].$etapa=$ANCHO"); done

mkdir -p "$SALIDA"
registrar_entorno "$SALIDA/entorno"
# Mismas flags que scripts/probar_gemm_paralelo.sh, para usar el binario validado.
compilar_arm "$FUENTE" "$BINARIO" "$SALIDA/compilacion" \
    -O2 -Wall -Wextra -Werror -fopenmp -fno-tree-vectorize -ffp-contract=off
{ echo "tamanos=$TAMANOS"; echo "nucleos=$NUCLEOS"; echo "ancho=$ANCHO"; echo "etapas=$ETAPAS"
  echo "rob=$ROB"; echo "iq=$IQ"; echo "forwardComSize=$FORWARD_COM"; echo "mem=${MEM:-512MiB}"
  echo "cpu=ArmO3CPU"
  echo "cache=clasica L1 32KiB/2v L2 256KiB/8v linea 64B DDR3_1600_8x8 2GHz"; } > "$SALIDA/parametros.txt"
lanzar() {
    local n=$1 c=$2 dir="$SALIDA/n$n/nucleos$c"
    if grep -qx 'estado=PASS' "$dir/validation.txt" 2>/dev/null; then
        echo "[omitida ] N=$n nucleos=$c"; return 0; fi
    echo "[iniciada] N=$n nucleos=$c"
    if ejecutar_gem5 "$dir" "$c" "$BINARIO" "$n $c" \
        "N=$n HILOS=$c HILOS_USADOS=$c CHECK=PASS errores=0" "${PARAMS[@]}"
    then echo "[lista   ] N=$n nucleos=$c"; else echo "[FALLO   ] N=$n nucleos=$c ($dir/validation.txt)"; fi
}

for n in $TAMANOS; do
    for c in $(printf '%s\n' $NUCLEOS | sort -rn); do   # las mas lentas primero
        esperar_cupo "$PARALELO"
        lanzar "$n" "$c" &
    done
done
wait || true

esperado=$(( $(wc -w <<<"$TAMANOS") * $(wc -w <<<"$NUCLEOS") ))
ok=$(contar_pass "$SALIDA"/n*/nucleos*/validation.txt)
echo "E4: $ok/$esperado corridas validas en $SALIDA"
(( ok == esperado )) || error "hay corridas invalidas; revisa validation.txt y run.log"
