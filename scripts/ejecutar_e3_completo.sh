#!/usr/bin/env bash
# Detengo el script si falla un paso o se usa una variable sin definir
set -euo pipefail

# Se busca la carpeta donde esta guardado este script
directorio_script="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Entrar a la raiz del repositorio para usar las rutas del proyecto
cd -- "$directorio_script/.."

# Comprobar Matplotlib antes de iniciar las simulaciones
python3 -c "import matplotlib"

# Se genera una carpeta nueva para guardar las corridas de esta ejecucion
salida="$(mktemp -d results/e3_repeticion.XXXXXX)"

# Mostrar en pantalla la carpeta para poder encontrar las corridas y los archivos finales
printf 'Carpeta de esta ejecucion: %s\n' "$salida"

# Ejecutar las 16 corridas de un tamano de N=64 y se guardan sus resultados en n64
bash scripts/barrido_vectorial.sh 64 "$salida/n64"

# Ejecutar las 16 corridas de un tamano de N=128 y se guardan sus resultados en n128
bash scripts/barrido_vectorial.sh 128 "$salida/n128"

# Se genero los tres CSV y las 2 figuras con las corridas que acaban de terminar
bash scripts/reproducir_e3.sh "$salida"
