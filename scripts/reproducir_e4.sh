#!/usr/bin/env bash
# Reproduce E4 completo: validacion nativa, barrido del kernel de B, barrido de la
# variante i-k-j, analisis, comparacion y evidencias.
#
# Uso:  bash scripts/reproducir_e4.sh
# Variables:
#   PARALELO=3   simulaciones simultaneas (aprox. nproc/2)
#   REHACER=0    1 = respalda y repite todo desde cero; 0 = reutiliza corridas ya validas
#   VALIDAR_B=0  1 = ademas corre scripts/probar_gemm_paralelo.sh (genera results/validation/...)
set -euo pipefail

RAIZ=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd); cd "$RAIZ"

PARALELO=${PARALELO:-3}
REHACER=${REHACER:-0}
VALIDAR_B=${VALIDAR_B:-0}
REPRO=results/e4_reproduccion
KERNELS=(gemm_paralelo gemm_paralelo_ikj)

mkdir -p "$REPRO"
exec > >(tee -a "$REPRO/reproducir.log") 2>&1
INICIO=$SECONDS

paso()  { printf '\n=== %s ===\n' "$*"; }
error() { echo "ERROR: $*" >&2; exit 1; }
contenedor() { bash scripts/arm_env.sh "$@"; }

requisitos() {
    command -v python3 >/dev/null || error "falta python3"
    python3 -c 'import matplotlib' 2>/dev/null || error "falta matplotlib (sudo apt install python3-matplotlib)"
    local f
    for f in src/gemm_paralelo.c src/gemm_paralelo_ikj.c scripts/arm_env.sh scripts/barrido_multiprocesador.sh \
             scripts/analizar_e4.py scripts/stats_gem5.py scripts/lib_evidencia.sh scripts/comparar_e4_ikj.py; do
        [[ -f $f ]] || error "falta $f"
    done
    grep -q 'BINARIO=\${BINARIO' scripts/barrido_multiprocesador.sh \
        || error "barrido_multiprocesador.sh debe tener: BINARIO=\${BINARIO:-\$RAIZ/bin/e4/arm}"
}

respaldar() {
    [[ $REHACER == 1 ]] || return 0
    local marca dir; marca=$(date +%Y%m%d_%H%M%S); dir="respaldo_e4_$marca"
    mkdir -p "$dir"
    for d in results/e4 results/e4_ikj results/e4_comparacion; do
        if [[ -d $d ]]; then mv "$d" "$dir/"; fi
    done
    grep -qxF 'respaldo_e4_*/' .git/info/exclude 2>/dev/null || echo 'respaldo_e4_*/' >> .git/info/exclude
    echo "Resultados previos movidos a $dir (excluido de Git localmente)"
}

validar_b() {
    [[ $VALIDAR_B == 1 ]] || return 0
    paso "0. Validacion del equipo (probar_gemm_paralelo.sh)"
    contenedor bash scripts/probar_gemm_paralelo.sh | tee "$REPRO/validacion_equipo.log"
    grep -q 'VALIDACION_PARALELA_OK' "$REPRO/validacion_equipo.log" || error "la validacion del equipo fallo"
}

validar_nativo() {
    paso "1. Validacion nativa de ambos kernels (N=16, 1/2/4/8 hilos)"
    local k destino
    for k in "${KERNELS[@]}"; do
        destino="$REPRO/nativo_$k.log"
        contenedor bash -c "set -e; gcc -O2 -Wall -Wextra -Werror -fopenmp -fno-tree-vectorize -ffp-contract=off src/$k.c -lm -o /tmp/$k; for h in 1 2 4 8; do /tmp/$k 16 \$h; done" > "$destino"
        cat "$destino"
        [[ $(grep -c 'CHECK=PASS errores=0' "$destino") == 4 ]] || error "$k no paso la validacion nativa"
    done
}

barrido() {   # barrido NOMBRE FUENTE BINARIO SALIDA
    local nombre=$1 fuente=$2 binario=$3 salida=$4
    paso "$nombre: barrido (N=64 y 128; 1, 2, 4 y 8 nucleos)"
    contenedor env PARALELO="$PARALELO" FUENTE="/work/$fuente" BINARIO="/work/$binario" \
        SALIDA="/work/$salida" bash scripts/barrido_multiprocesador.sh
    paso "$nombre: analisis (speedup, eficiencia, Amdahl, memoria, balance)"
    python3 scripts/analizar_e4.py --raiz "$salida" | tee "$salida/analisis_consola.txt"
}

simulaciones_insts() {
    awk '/End Simulation Statistics/{exit} /^simInsts/{print $2; exit}' "$1/stats.txt"
}

comparar() {
    paso "4. Comparacion kernel de B vs i-k-j"
    python3 scripts/comparar_e4_ikj.py
    local destino=results/e4_comparacion d rel
    {
        echo "# simInsts de la ROI (primer bloque de stats): ambos kernels deben hacer un trabajo similar"
        printf '%-18s %-14s %-14s\n' corrida kernel_B kernel_ikj
        for d in results/e4/n*/nucleos*; do
            rel=${d#results/e4/}
            printf '%-18s %-14s %-14s\n' "$rel" "$(simulaciones_insts "$d")" "$(simulaciones_insts "results/e4_ikj/$rel")"
        done
    } > "$destino/instrucciones.txt"
    cat "$destino/instrucciones.txt"
    sha256sum results/e4/summary/e4_metricas.csv results/e4_ikj/summary/e4_metricas.csv > "$destino/entradas.sha256"
}

manifest() {
    local salida="$REPRO/manifest.txt"
    {
        echo "fecha=$(date -Is)"
        echo "commit=$(git rev-parse HEAD 2>/dev/null || echo desconocido)"
        echo "archivos_modificados=$(git status --porcelain 2>/dev/null | wc -l)"
        echo "host=$(uname -srm) nproc=$(nproc)"
        echo "paralelo=$PARALELO rehacer=$REHACER"
        echo "imagen=$(grep -o 'ghcr.io[^ "]*' scripts/arm_env.sh | head -n1)"
        echo "python=$(python3 --version 2>&1)"
        echo "matplotlib=$(python3 -c 'import matplotlib; print(matplotlib.__version__)')"
        echo "duracion_s=$((SECONDS - INICIO))"
        echo "--- sha256 de fuentes y scripts ---"
        sha256sum src/gemm_paralelo.c src/gemm_paralelo_ikj.c scripts/arm_env.sh \
            scripts/lib_evidencia.sh scripts/barrido_multiprocesador.sh scripts/stats_gem5.py \
            scripts/analizar_e4.py scripts/comparar_e4_ikj.py scripts/reproducir_e4.sh
    } > "$salida"
    find results/e4 results/e4_ikj results/e4_comparacion -type f \
        \( -name '*.csv' -o -name '*.md' -o -name '*.png' -o -name '*.pdf' -o -name stats.txt \) -print0 \
        | sort -z | xargs -0 sha256sum > "$REPRO/evidencias.sha256"
}

verificar() {
    local fallos=0 base ok f
    for base in results/e4 results/e4_ikj; do
        ok=$(grep -l '^estado=PASS' "$base"/n*/nucleos*/validation.txt 2>/dev/null | wc -l)
        if [[ $ok != 8 ]]; then echo "FALTA: $base tiene $ok/8 corridas validas"; fallos=1; fi
        for f in summary/e4_metricas.csv summary/e4_por_nucleo.csv summary/e4_resumen.md \
                 summary/e4_stats.sha256 summary/e4_speedup.png summary/e4_speedup.pdf \
                 summary/e4_eficiencia.png summary/e4_l1d.png summary/e4_balance.png \
                 entorno/manifest.txt compilacion/build_command.txt compilacion/binary.sha256 \
                 compilacion/kernel_asm.txt parametros.txt analisis_consola.txt; do
            if [[ ! -s $base/$f ]]; then echo "FALTA: $base/$f"; fallos=1; fi
        done
    done
    for f in e4_comparacion.csv e4_comparacion.md e4_comparacion.png e4_comparacion.pdf \
             instrucciones.txt entradas.sha256; do
        if [[ ! -s results/e4_comparacion/$f ]]; then echo "FALTA: results/e4_comparacion/$f"; fallos=1; fi
    done
    return $fallos
}

requisitos
respaldar
validar_b
validar_nativo
barrido "2. Kernel de B (resultado oficial)" src/gemm_paralelo.c     bin/e4/arm     results/e4
barrido "3. Variante i-k-j (extra comparativo)" src/gemm_paralelo_ikj.c bin/e4_ikj/arm results/e4_ikj
comparar
manifest

paso "Verificacion final"
if verificar; then
    echo "E4 COMPLETO: todas las evidencias existen. Duracion: $((SECONDS - INICIO)) s"
    echo "Resumen de la comparacion:"; cat results/e4_comparacion/e4_comparacion.md
else
    error "faltan evidencias; revisa los mensajes anteriores y $REPRO/reproducir.log"
fi
