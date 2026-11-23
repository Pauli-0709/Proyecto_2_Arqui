#!/usr/bin/env bash
# Se detiene la prueba cuando falla un comando.
set -euo pipefail

# Se comprueba que el sistema sea ARM de 64 bits.
if [[ "$(uname -m)" != aarch64 ]]; then
    # Se explica que hace falta otra maquina para la prueba nativa.
    echo "ERROR: se necesita Linux ARM64 con SVE." >&2
    # Se termina antes de intentar compilar.
    exit 1
# Se termina la comprobacion de la arquitectura.
fi

# Se comprueba que Linux anuncie soporte para SVE.
if ! grep -Eq '^Features[[:space:]]*:.*[[:space:]]sve([[:space:]]|$)' /proc/cpuinfo; then
    # Se informa que SVE no esta disponible en este sistema.
    echo "ERROR: Linux no reporta soporte para SVE." >&2
    # Se termina antes de ejecutar instrucciones SVE.
    exit 1
# Se termina la comprobacion de SVE.
fi

# Se entra a la raiz del repositorio a partir de la ruta del script.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

# Se prepara una carpeta local para la prueba.
mkdir -p .local
# Se crea una carpeta distinta para conservar cada intento de forma independiente
salida=$(mktemp -d .local/gemm_sve_nativo.XXXXXX)

# Se muestra en pantalla donde se van a guardar los archivos
printf 'SALIDA=%s\n' "$salida"

# Se guarda la arquitectura correspondiente como evidencia de la prueba
uname -m > "$salida/arquitectura.txt"

# Se registra la version de GCC
gcc --version > "$salida/compilador.txt"

# Se registra el sha del archivo C
sha256sum src/gemm_sve.c > "$salida/fuente.sha256"

# Se compila el GEMM con SVE y el mismo guarda el registro de compilacion
gcc -std=c11 -O2 -Wall -Wextra -Wpedantic -march=armv8-a+sve -msve-vector-bits=scalable -ffp-contract=off src/gemm_sve.c -lm -o "$salida/gemm_sve" 2>&1 | tee "$salida/build.log"

# Se ejecuta la multiplicacion de matrices de 16 por 16
"$salida/gemm_sve" 16 2>&1 | tee "$salida/n16.log"

# Se comprueba que el programa reporto la longitud vectorial usada
grep -Eq '^SVE VL_BITS=[1-9][0-9]* ELEMENTOS_FLOAT=[1-9][0-9]*$' "$salida/n16.log"

# Se comprueba que todos los elementos coinciden con la referencia ejecutada
grep -q '^N=16 CHECK=PASS errores=0 ' "$salida/n16.log"

# Se confirma el exito del mismo despues de ejecutar las comprobaciones
echo "VALIDACION_SVE_NATIVA_OK N=16"
