#!/usr/bin/env bash
# Reproduce E6 completo: validacion del modelo de costo, barridos, analisis y hashes.
# Uso (dentro del entorno ARM): bash scripts/reproducir_e6.sh
set -euo pipefail

RAIZ=$(cd -- "$(dirname -- "$0")/.." && pwd)
cd "$RAIZ"

TAMANOS=${TAMANOS:-"128 256"}   # 128 es el N del enunciado; 256 es la sensibilidad al tamano
CSV=configs/e6_configuraciones.csv

python3 scripts/modelo_costo.py --validar "$CSV" 32
python3 -c 'import matplotlib'

for n in $TAMANOS; do
    bash scripts/barrido_integracion.sh "$n"
    python3 scripts/analizar_e6.py "results/e6/n$n"
done

# Sensibilidad al presupuesto: mismas corridas filtradas con costo <= 16.
python3 scripts/analizar_e6.py results/e6/n128 --presupuesto 16

mkdir -p results/e6/reproduccion
{
    printf 'FECHA=%s\n' "$(date -u +%FT%TZ)"
    printf 'COMMIT=%s\n' "$(git rev-parse HEAD 2>/dev/null || echo desconocido)"
    printf 'TAMANOS=%s\n' "$TAMANOS"
} > results/e6/reproduccion/manifest.txt
sha256sum "$CSV" src/gemm_paralelo_sve.c scripts/barrido_integracion.sh scripts/analizar_e6.py \
    scripts/modelo_costo.py results/e6/n*/summary/*.csv > results/e6/reproduccion/evidencias.sha256

printf 'REPRODUCCION_E6_OK TAMANOS="%s"\n' "$TAMANOS"
