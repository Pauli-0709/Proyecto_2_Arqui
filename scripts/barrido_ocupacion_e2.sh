#!/usr/bin/env bash

# Ejecutar con Bash y detener el barrido si falla un comando
set -euo pipefail

#=================================================================

# Trabajar desde la raiz del proyecto aunque el script se abra desde otra carpeta, para evitar errores
cd "$(dirname "$0")/.."


# Probar los 2 tamanos de matriz bajo analisis
for n in 64 128; do

    # Probar los 4 anchos del nucleo
    for ancho in 1 2 4 8; do

        # Probar los 3 tamanos del ROB
        for rob in 32 64 192; do
            # Se genera el nombre del archivo que corresponde a esta combinacion
            archivo="results/e2/ocupacion/n${n}_ancho${ancho}_rob${rob}.csv"

            # Reutilizar las muestras ya guardadas por el medidor
            if [[ -s "$archivo" ]]; then
                # Mensaje en patalla para saber cual configuracion ya se habia medido
                echo "MUESTRAS_EXISTENTES N=$n ANCHO=$ancho ROB=$rob"
            else
                # Ejecutar el medidor para la configuracion que falta
                python3 scripts/medir_ocupacion_e2.py "$n" "$ancho" "$rob"
            fi

        done  # Pasar al siguiente ROB

    done  # Pasar al siguiente ancho

done  # Pasar al siguiente tamano

# Mensaje final que indica que se recorrio la lista completa
echo "BARRIDO_OCUPACION_E2_OK"
