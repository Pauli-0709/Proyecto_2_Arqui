#!/usr/bin/env bash

# Detenerse si alguno de los pasos falla
set -euo pipefail

#==========================================================


# Entrar en la raiz del proyecto en local
cd "$(dirname "$0")/.."

# Verificar las 12 configuraciones oficiales de un tamano de N=64
bash scripts/barrido_superescalar.sh 64

# Verificar las 12 configuraciones oficiales de un tamano de N=128
bash scripts/barrido_superescalar.sh 128

# Regenerar el CSV de rendimiento desde los archivos stats.txt
python3 scripts/resumir_e2.py

# Usar las muestras de ocupacion publicadas para regenerar el otro archivo CSV y las 2 figuras correspondientes
python3 scripts/graficar_e2.py

# Confirmar que los pasos anteriores terminaron correctamente, en pantalla
echo "REPRODUCCION_E2_OK"
