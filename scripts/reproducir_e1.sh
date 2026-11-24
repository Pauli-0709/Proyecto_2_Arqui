#!/usr/bin/env bash

# Detiene la reproduccion si falla un paso.
set -euo pipefail

#--------------------------------------------------

# Encuentra la raiz del repositorio
raiz=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

# Entrar al repositorio
cd -- "$raiz"

# Comprobar que Python pueda generar correctamente el grafico antes de simular.
python3 -c 'import matplotlib'



mkdir -p .local
# Reserva una carpeta distinta para cada una de las repeticiones del script
salida=$(mktemp -d .local/e1.XXXXXX)

# Muestra en pantalla donde quedaron los archivos, incluso si una corrida falla.
printf 'Salida de E1: %s\n' "$salida"


# Ejecuta y valida las 6 corridas con tamanos de N=64 y de N=128.
bash scripts/ejecutar_linea_base.sh barrido "$salida/corridas"

# Extraer las metricas de la region de interes y genera el archivo CSV.
python3 scripts/resumir_linea_base.py \
    "$salida/corridas" "$salida/resumen_linea_base.csv"

# Generar el grafico de IPC y los ciclos. Ademas, mostrar la aceleracion del O3.
python3 scripts/graficar_linea_base.py \
    "$salida/resumen_linea_base.csv" "$salida/grafico_linea_base.png"


# Confirma que todos los pasos terminaron correctamente en pantalla.
printf 'REPRODUCCION_E1_OK SALIDA=%s\n' "$salida"
