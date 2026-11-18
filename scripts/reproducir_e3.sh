#!/usr/bin/env bash
# La linea anterior selecciona Bash para ejecutar este archivo

# Detener el proceso si falla un comando o se usa una variable no definida
set -euo pipefail

# Informar un fallo
trap 'printf "ERROR: se interrumpio la reproduccion de E3.\n" >&2' ERR

# Localizar la carpeta del script aunque se invoque desde otra ubicacion
directorio_script="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Cambiar a la raiz del repositorio
cd -- "$directorio_script/.."

# Verificar Matplotlib antes de reemplazar cualquier resultado
python3 -c "import matplotlib"

# Regenerar las metricas de las distintas 32 corridas realizadas y las 16 comparaciones correspondientes
python3 scripts/resumir_e3.py

# Regenerar la comparacion de 8 metricas de memoria
python3 scripts/comparar_memoria_e3.py

# Generar las figuras PNG y SVG usando el resumen actualizado
python3 scripts/graficar_e3.py

# Confirmar el exito solamente despues de completar todos los pasos anteriores.
printf 'REPRODUCCION_E3_OK CSV=3 FIGURAS=2\n'
