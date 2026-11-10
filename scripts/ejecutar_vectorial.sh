#!/usr/bin/env bash
# La proxima linea le indica al OS (kernel) que el archivo de texto debe ser ejecutado utilizando el interprete Bash

#=========================================================================================
# Ejecuta una corrida de GEMM escalar o SVE con hardware comun
# Se utiliza dentro del DOCKER del proyecto
#=============================================================================

# Configuracion utilizada:
# 1) e: sale inmediatamente si cualquier comando falla (esta va a devolver un codigo != 0)
# 2) u: trata el uso de variables no definidas como un error
# 3) o pipefail: hace que una tubería falle si cualquiera de sus distintos subcomandos llega a fallar
set -euo pipefail

# El siguiente IF comprueba que el directorio de salida este dentro de la ruta de results/# Imporesion en pantalla del error
trap 'echo "ERROR en linea $LINENO. Revisar los registros." >&2' ERR

# Determina la carpeta del proyecto
directorio_proyecto=$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
)
# Cambia el directorio de trabajo al directorio raiz del proyecto
cd "$directorio_proyecto"

# -------------------------------------
# 1. Validar argumentos
# ----------------------------------------

# Verifica que se hayan pasado exactamente 4 argumentos al script
if (( $# != 4 )); then
    echo "Uso: bash scripts/ejecutar_vectorial.sh scalar|sve N VL SALIDA" >&2
    exit 1
fi

# Asigna los argumentos a variables en el codigo
programa=$1
tamano=$2
vl_bits=$3
salida=$4

# Valida que la variable del programa sea exactamente scalar o sve
case "$programa" in
    scalar|sve) ;;
    *) echo "Programa debe ser scalar o sve." >&2; exit 1 ;;
esac

# Valida que la variable tamano contenga uno de los valores permitidos para las pruebas
case "$tamano" in
    16|17|64|128) ;;
    *) echo "N debe ser 16, 17, 64 o 128." >&2; exit 1 ;;
esac

# Valida que la longitud del vector este en el rango permitido en incrementos de 128 bits cada uno de ellos
case "$vl_bits" in
    128|256|384|512|640|768|896|1024) ;;
    *) echo "VL debe estar entre 128 y 1024 en pasos de 128." >&2; exit 1 ;;
esac

# El siguiente IF comprueba que el directorio de salida este dentro de la ruta de results/
if [[ "$salida" != results/* || "$salida" == *..* ]]; then
    echo "La salida debe estar dentro de results/, sin '..'." >&2
    exit 1
fi

# El siguinete IF va a verificar si la carpeta de salida ya existe para de esta manera poder evitar el sobrescribir las evidencias de corridas previas
if [[ -e "$salida" ]]; then
    echo "La carpeta ya existe: $salida" >&2
    echo "Usa una carpeta nueva para conservar las evidencias." >&2
    exit 1
fi

# ------------------------------------------------------------
# 2. Comprobar herramientas y cargar hardware
# ------------------------------------------------------

# Archivos necesarios para la simulacion
simulador=/opt/gem5/build/ARM_MESI/gem5.opt
configuracion=/opt/gem5/configs/deprecated/example/se.py
biblioteca=/opt/gem5/util/m5/build/arm64/out/libm5.a
fuente="src/gemm_${programa}.c"

# Bucle para comprobar que todas las herramientas necesarias esten instaladas y disponibles en el sistema
for herramienta in \
    aarch64-linux-gnu-gcc aarch64-linux-gnu-objdump \
    python3 file sha256sum
do
    command -v "$herramienta" >/dev/null
done

# Verificar que los binarios y scripts existan
test -x "$simulador"
test -f "$configuracion"
test -f "$biblioteca"
test -f /opt/gem5/include/gem5/m5ops.h
test -f "$fuente"

# Cargar las variables y configuraciones del archivo de opciones vectoriales
source configs/configuracion_vectorial.sh

# Crear la carpeta sin sobrescribir una existente
mkdir -p -- "$(dirname -- "$salida")"
mkdir -- "$salida"
salida=$(cd -- "$salida" && pwd)

# Cada corrida tiene un ejecutable independiente
mkdir -p bin
ejecutable=$(mktemp "$directorio_proyecto/bin/gemm_e3_XXXXXX")

# ---------------------------------------------------------------------------
# 3. Guardar fuentes, configuracion y versiones
# --------------------------------------------------------------------

# Copia los archivos fuente y scripts a la carpeta de salida para mantener de esta manera un registro de la configuracion
cp "$fuente" "$salida/"
cp configs/configuracion_vectorial.sh "$salida/"
cp scripts/ejecutar_vectorial.sh "$salida/"

# Calcula y guarda el hash SHA256 de los archivos fuente y de configuracion para verificar su integridad futura
sha256sum "$fuente" > "$salida/source.sha256"
sha256sum "$configuracion" > "$salida/se_py.sha256"

# Guarda la info de la version del compilador cruzado
aarch64-linux-gnu-gcc --version > "$salida/compiler.txt"
"$simulador" --build-info > "$salida/gem5_build_info.txt" 2>&1

# Escribe los parametros del experimento en un archivo de texto
printf 'PROGRAMA=%s\nN=%s\nVL_BITS=%s\n' \
    "$programa" "$tamano" "$vl_bits" > "$salida/parametros.txt"

# ---------------
# 4. Compilar
# ---------------

# Se utilizan las mismas opciones de optimizacion y arquitectura
# Desactivar autovectorizacion mantiene escalar el kernel scalar
# Los intrinsecos SVE siguen generando instrucciones vectoriales

# Se define el arreglo con los argumentos de compilacion
# aarch64-linux-gnu-gcc: el compilador cruzado para ARM64
# -std=c11 -O2 -static: usa estandar C11, optimizacion nivel 2, y enlazado estatico
# -Wall -Wextra -Wpedantic: activa todas las advertencias posibles para un codigo limpio
# -march=armv8-a+sve: indica a GCC que genere codigo para la arquitectura ARMv8-A con soporte SVE habilitado
# -msve-vector-bits=scalable: indica que el tamano del vector SVE es escalable (osea dinamico) y no es fijo
# -fno-tree-vectorize: evita que el compilador vectorice bucles automaticamente
# -fno-tree-slp-vectorize: forzar que se evalue unicamente la vectorizacion manual
# -ffp-contract=off: desactiva instrucciones FMA automaticas para control matematico
# -DUSE_GEM5: define una macro de preprocesador para el codigo C
# -I/opt/gem5/include: incluye la carpeta de cabeceras de gem5
# "$salida/gemm_${programa}.c": archivo fuente a compilar
# "$biblioteca": enlaza la biblioteca m5
# -lm: enlaza la biblioteca matematica estandar (libm)
# -o "$ejecutable": especifica el archivo de salida
compilar=(
    aarch64-linux-gnu-gcc
    -std=c11 -O2 -static
    -Wall -Wextra -Wpedantic
    -march=armv8-a+sve
    -msve-vector-bits=scalable
    -fno-tree-vectorize
    -fno-tree-slp-vectorize
    -ffp-contract=off
    -DUSE_GEM5
    -I/opt/gem5/include
    "$salida/gemm_${programa}.c"
    "$biblioteca"
    -lm
    -o "$ejecutable"
)

# Formatea y se guarda el comando de compilacion en un archivo para referencia
printf '%q ' "${compilar[@]}" > "$salida/build_command.txt"
# Anade un salto de linea al final del archivo de comando
printf '\n' >> "$salida/build_command.txt"


# Ejecutar el comando de compilacion y redirigir la salida estandar y de error a un registro de tipo log
"${compilar[@]}" > "$salida/build.log" 2>&1

# Guarda el hash
sha256sum "$ejecutable" > "$salida/binary.sha256"
file "$ejecutable" > "$salida/binary_info.txt"

# Comprueba el binario para la arquictetura ARM aarch64 y que este enlazada de forma estatica
grep -q 'ARM aarch64' "$salida/binary_info.txt"
grep -q 'statically linked' "$salida/binary_info.txt"

# Desensamble del codigo (kernel) - codigo ensamblador
aarch64-linux-gnu-objdump \
    -d --disassemble="gemm_${programa}" \
    "$ejecutable" > "$salida/kernel_asm.txt"

# Comprobar que se obtuvo el kernel solicitado
grep -q "<gemm_${programa}>:" "$salida/kernel_asm.txt"


# Se activa el IF si el programa compilado corresponde a la version SVE
if [[ "$programa" == sve ]]; then
    grep -Eq 'fmul[[:space:]]+z[0-9]+\.s' "$salida/kernel_asm.txt"
    grep -Eq 'fadd[[:space:]]+z[0-9]+\.s' "$salida/kernel_asm.txt"
else
    # Rechazar registros vectoriales SVE o SIMD en el kernel escalar
    if grep -Eq \
        '(^|[[:space:],{])(z[0-9]+|p[0-9]+|v[0-9]+)([./[:space:],}]|$)' \
        "$salida/kernel_asm.txt"
    then
    	# Si se detectan registros vectoriales muestra un mensaje de error y detiene el script
        echo "Se detectaron registros vectoriales en GEMM escalar." >&2
        exit 1
    fi

	# Comprobar que existan instrucciones escalares de multiplicacion con registros de tipo s
    grep -Eq 'fmul[[:space:]]+s[0-9]+' "$salida/kernel_asm.txt"
    # Comprobar que existan instrucciones escalares de suma con registros de tipo s
    grep -Eq 'fadd[[:space:]]+s[0-9]+' "$salida/kernel_asm.txt"
fi

# -------------------------
# 5. Ejecutar gem5
# ------------------------

# Se prepara el arreglo con el comando de ejecucion del simulador y todos sus argumentos
comando=("$simulador" -d "$salida" "$configuracion" "${opciones_vectoriales[@]}" -c "$ejecutable" -o "$tamano")

# Guarda el comando de simulacion ejecutado en un archivo
printf '%q ' "${comando[@]}" > "$salida/command.txt"
printf '\n' >> "$salida/command.txt"

# Impresion en pantalla de info
echo "Ejecutando E3: programa=$programa N=$tamano VL=$vl_bits"
echo "Resultados: $salida"


# inicializa el codigo de salida en 0
codigo=0
"${comando[@]}" > "$salida/run.log" 2>&1 || codigo=$?

# Guarda el codigo de salida retornado por gem5 en un archivo de texto
printf '%s\n' "$codigo" > "$salida/exit_code.txt"

# Este IF verifica que si el simulador genero un error
if (( codigo != 0 )); then
    echo "gem5 fallo. Revisar $salida/run.log" >&2
    exit 1
fi

# Genera un busqueda en el registro de la simulacion que la comprobacion realizada de resultados matriciales haya pasado sin ningun error
grep -Eq \
    "^N=$tamano CHECK=PASS errores=0 " \
    "$salida/run.log"

# Este IF verifica que la corrida sea SVE y que compruebe las configuraciones del vector
if [[ "$programa" == sve ]]; then
    grep -Fqx \
        "SVE VL_BITS=$vl_bits ELEMENTOS_FLOAT=$((vl_bits / 32))" \
        "$salida/run.log"
fi

# Se asegura que el simulador gem5 haya generado los archivos de configuracion y estadisticas respectivos y esperados sin que estos esten vacios
test -s "$salida/config.ini"
test -s "$salida/config.json"
test -s "$salida/stats.txt"

# ----------------------------------------------------------------
# 6. Verificar hardware efectivo y primer bloque de la ROI
# --------------------------------------------------------------

# Inicio de la progra en python
python3 - "$salida" "$vl_bits" <<'PY'
import configparser
import math
import sys
from pathlib import Path

# asigna la ruta del directorio de salida desde el primer argumento del script python
salida = Path(sys.argv[1])
vl = int(sys.argv[2])

# Inicializa el analizador de la configuraicon
config = configparser.ConfigParser(interpolation=None)
config.optionxform = str
# Lectura y procesamiento del archivo config.ini generado por gem5
config.read(salida / "config.ini")

# Se define una funcion auxiliar para validar que los valores de configuracion coincidan exactamente con un objetivo
def comprobar(seccion, parametro, esperado):
    obtenido = config[seccion][parametro]

	# Se evalua si no coincide con la cadena esperada, deitne la ejecucion impriendo un error
    if obtenido != str(esperado):
        raise SystemExit(
            f"ERROR: {seccion}.{parametro}={obtenido}; "
            f"se esperaba {esperado}"
        )

# Un solo nucleo O3
cpus = [
    seccion for seccion in config.sections()
    if config[seccion].get("type") == "BaseO3CPU"
]

# Verificar que exista exactamente un nucleo llamado system.cpu
if cpus != ["system.cpu"]:
    raise SystemExit(f"ERROR: CPU inesperadas: {cpus}")

# Se itera sobre las diferentes etapas del procesador simulado
for parametro in (
    "fetchWidth", "decodeWidth", "renameWidth",
    "dispatchWidth", "issueWidth", "wbWidth", "commitWidth"
):
	# Se valida que el ancho de procesamiento en cada etapa sea de 2
    comprobar("system.cpu", parametro, 2)

# Se comprueba que el ROB tenga exactamente 192 entradas asignadas
comprobar("system.cpu", "numROBEntries", 192)
# Se verifica que la cola de instrucciones cuente con 64 entradas
comprobar("system.cpu", "numIQEntries", 64)
# Se verifica que el tamano de comunicacion hacia adelante sea 256
comprobar("system.cpu", "forwardComSize", 256)

# Se extrae las arquitecturas de conjunto de instrucciones vinculadas a la CPU
isas = config["system.cpu"]["isa"].split()

# Se valida que haya una sola definicion de ISA indicando que hay un solo hilo de hardware
if len(isas) != 1:
    raise SystemExit("ERROR: se esperaba una ISA para un hilo.")

# comprueba que el tipo de arquitectura sea ARM
comprobar(isas[0], "type", "ArmISA")
# verifica que la longitud configurada en el vector hardware coincida con la proporcionada
comprobar(isas[0], "sve_vl_se", vl // 128)

for seccion, tamano, vias in (("system.cpu.icache", 32768, 2), ("system.cpu.dcache", 32768, 2), ("system.l2", 262144, 8),):
	# Comprobar que el tamano de la cache sea el esperado
    comprobar(seccion, "size", tamano)
	# Comprobar que la asociatividad de la cache analizada corresponda al numero de vias indicado
    comprobar(seccion, "assoc", vias)


# Comprobar que la linea de cache del sistema tenga 64 bytes
comprobar("system", "cache_line_size", 64)
# Asegurar que el rango de memoria configurado tenga 512 MiB
comprobar("system", "mem_ranges", "0:536870912")

# Leer solamente el primer bloque completo de estadisticas
texto = (salida / "stats.txt").read_text()
inicio = texto.index("Begin Simulation Statistics")
fin = texto.index("End Simulation Statistics", inicio)

nombres = ("simInsts", "simTicks", "simFreq", "system.cpu.numCycles")
metricas = {}


# Se itera linea por linea unicamente sobre la porcion extraida del bloque de estadisticas
for linea in texto[inicio:fin].splitlines():
	# Divide la linea en sus componentes usando espacios en blanco
    partes = linea.split()
    if len(partes) >= 2 and partes[0] in nombres:
        metricas[partes[0]] = float(partes[1])

# Se recorre la lista de estadisticas necesarias
for nombre in nombres:
	# obtiene su valor o asigna 0 por defecto
    valor = metricas.get(nombre, 0)
    if not math.isfinite(valor) or valor <= 0:
        raise SystemExit(f"ERROR: metrica ausente o invalida: {nombre}")

# Los relojes de config.ini se expresan en ticks por ciclo.
frecuencia_ticks = metricas["simFreq"]


# Se itera sobre las secciones de dominio de reloj del nucleo de CPU y los sistema con sus valores esperados en Hz
for seccion, frecuencia_hz in (("system.cpu_clk_domain", 2e9), ("system.clk_domain", 1e9),):
    periodo = float(config[seccion]["clock"])
    if not math.isclose(
        frecuencia_ticks / periodo, frecuencia_hz, rel_tol=1e-9
    ):
        raise SystemExit(f"ERROR: frecuencia incorrecta en {seccion}")

# Impresion en pantalla de info que todo esta OK
print("CONFIGURACION_VECTORIAL_OK")
print("ROI_E3_OK")
PY

# Este archivo se crea solamente si pasan todas las comprobaciones
printf 'VALIDACION_E3_OK PROGRAMA=%s N=%s VL_BITS=%s\n' \
    "$programa" "$tamano" "$vl_bits" \
    > "$salida/validation.txt"

cat "$salida/validation.txt"
