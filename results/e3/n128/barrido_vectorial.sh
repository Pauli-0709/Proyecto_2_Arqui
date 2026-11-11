#!/usr/bin/env bash
# La proxima linea le indica al OS (kernel) que el archivo de texto debe ser ejecutado utilizando el interprete Bash

#=========================================================================
# Barrido E3 para un tamano de matriz
# Ejecuta escalar y SVE para ocho longitudes vectoriales
# Debe ejecutarse dentro del contenedor del proyecto
#===================================================================

# Configuración utilizada:
# 1) e: sale inmediatamente si cualquier comando falla (esta va a devolver un codigo != 0)
# 2) u: trata el uso de variables no definidas como un error
# 3) o pipefail: hace que una tubería falle si cualquiera de sus distintos subcomandos llega a fallar
set -euo pipefail
trap 'echo "ERROR en linea $LINENO. El barrido quedo incompleto; revisar los registros." >&2' ERR

# En el siguiente comando se va a ubicar de forma dinamica en la raiz del repositorio basandose en la ubicacion del script
directorio_proyecto=$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
)
cd "$directorio_proyecto"

# -----------------------
# 1. Validar argumentos
# -----------------------

# Se verifica que se hayan pasado de 1 o 2 argumentos al script
if (( $# < 1 || $# > 2 )); then
	# Impresion en pantalla del uso correcto del script por la salida de error
    echo "Uso: bash scripts/barrido_vectorial.sh N [SALIDA]" >&2
    exit 1
fi

# Se asigna el primer argumento a la variable del tamano de la matriz
tamano=$1

# Se valida que el tamano coincida con los admitidos oficialmente por la prueba
case "$tamano" in
    64|128) ;;
	# Si el tamano no es el mismo muestra el error y para la ejecucion
    *) echo "El barrido oficial admite N=64 o N=128." >&2; exit 1 ;;
esac

# Se asigna el segundo argumento (ruta de salida) o usa un valor por defecto  si no esta
salida="${2:-results/e3/n${tamano}}"


#Verificar que el directorio este dentro de la ruta de  results y no contenga rutas relativas hacia atras
if [[ "$salida" != results/* || "$salida" == *..* ]]; then
	# Impresion en pantalla del errod de ruta y termina la ejecucion
    echo "La salida debe estar dentro de results/, sin '..'." >&2
    exit 1
fi

# Verificar si el directorio de salida ya existe
if [[ -e "$salida" ]]; then
	# Impresion en pantalla del error de sobreescribir
    echo "La carpeta ya existe: $salida" >&2
    echo "Usa una carpeta nueva para conservar los resultados." >&2
    exit 1
fi

# -------------------------------------------------------
# 2. Comprobar entorno y conservar evidencia del barrido
# -------------------------------------------------------

# Se comprueba que el ejecutable del simulador gem5 exista
test -x /opt/gem5/build/ARM_MESI/gem5.opt
# Se comprueba el compilador cruzado
command -v aarch64-linux-gnu-gcc >/dev/null
# Se comprueba que exista python
command -v python3 >/dev/null


# Se define el arreglo con todos los archivos fuente, de configuracion y scripts requeridos para el barrido
archivos=(src/gemm_scalar.c src/gemm_sve.c configs/configuracion_vectorial.sh scripts/ejecutar_vectorial.sh scripts/barrido_vectorial.sh)

# Iteracion sobre el arreglo de los archivos que son obligatorios
for archivo in "${archivos[@]}"; do
	# Verificar que cada archivo analizado exista
    test -f "$archivo"
done

# Generar las rutas de las carpetas que van a contener la salida (sin sobreescribir resultados previos)
mkdir -p -- "$(dirname -- "$salida")"
mkdir -- "$salida"

# copia el script de barrido actual al directorio de resultados como evidencia
cp scripts/barrido_vectorial.sh "$salida/"

# Detectar cambios en programas y scripts durante el barrido
sha256sum "${archivos[@]}" > "$salida/entradas.sha256"

# guarda un archivo de texto con la configuracion del barrido definiendo el tamano evaluado y las corridas esperadas
printf 'N=%s\nCORRIDAS_ESPERADAS=16\n' \
    "$tamano" > "$salida/barrido.txt"

# ----------------------------------------------------
# 3. Ejecutar las 16 corridas de forma secuencial
# ---------------------------------------------------

# Inicializa el contador de corridas completadas con exito
corridas=0

# Itera sobre las 8 longitudes del vector SVE, las cuales seran pasadas al la configuracuion
for vl in 128 256 384 512 640 768 896 1024; do
	# Iterar sobre las 2 versiones de implementacion del kernel
    for programa in scalar sve; do

        # No mezclar resultados de distintas versiones del codigo
        sha256sum --check --status "$salida/entradas.sha256"

		# Define la ruta para la carpte de resultados
        corrida="$salida/vl${vl}/${programa}"
        # Define la ruta para el archivo log que alamcena los datos resultantes
        registro="$salida/lanzador_${programa}_vl${vl}.log"

		# Separador
        echo "--------------------------------------------------"
        # Impresion en pantalla del progreso actual (corrida actual vs total) y otros datos como tamano y VL
        echo "Corrida $((corridas + 1))/16: N=$tamano VL=$vl $programa"

        # pipefail conserva el fallo del lanzador aunque se use tee
        bash scripts/ejecutar_vectorial.sh \
            "$programa" "$tamano" "$vl" "$corrida" \
            2>&1 | tee "$registro"

        # Exigir la confirmacion exacta del lanzador
        esperado="VALIDACION_E3_OK PROGRAMA=$programa N=$tamano VL_BITS=$vl"
        grep -Fxq "$esperado" "$corrida/validation.txt"

        # Confirmar que siguen presentes las evidencias principales
        for archivo in stats.txt config.ini config.json run.log; do
			# Verificar que cada evidencia exista y que la misma contenga datos confirmando una corrida que este completa
            test -s "$corrida/$archivo"
        done

        # Comprobar que los archivos de entrada no cambiaron.
        sha256sum --check --status "$salida/entradas.sha256"

		# Se incrementa en +1 el contador validado de corridas al completar todas las comprobaciones
        corridas=$((corridas + 1))

		# Anade una linea de confirmacion y del progreso parcial en el log del barrido
        printf 'CORRIDA_OK PROGRAMA=%s N=%s VL_BITS=%s\n' \
            "$programa" "$tamano" "$vl" \
            >> "$salida/progreso.txt"
    done
done

# ---------------------------------------------------------
# 4. Registrar finalizacion solamente si terminaron todas
# ----------------------------------------------------------

# Se comprueba que el total de corridas sea igual a 16 para asegurar la integridad de toda la ejecucion en bloque
test "$corridas" -eq 16

# Se escribe el archivo final que certifica la validez de todo el grupo de experimentos realizados con las 16 corridas reportadas
printf 'BARRIDO_E3_COMPLETO N=%s CORRIDAS=%s\n' \
    "$tamano" "$corridas" \
    > "$salida/validation.txt"

# Genera en consola una salida de resultado final
cat "$salida/validation.txt"
