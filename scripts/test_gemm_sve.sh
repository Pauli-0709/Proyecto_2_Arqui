#!/usr/bin/env bash
# La proxima linea le indica al OS (kernel) que el archivo de texto debe ser ejecutado utilizando el interprete Bash


#==========================================================================================================================
# Validar GEMM SVE mediante este script con el uso de matrices y diferentes longitudes vectoriales
# Este script se tiene que ejecutar dentro del docker
#=====================================================================================================================


#Configuracion utilizada:
# 1) e: sale inmediatamente si cualquier comando falla (esta va a devolver un codigo != 0)
# 2) u: trata el uso de variables no definidas como un error
# 3) o pipefail: hace que una tubería falle si cualquiera de sus distintos subcomandos llega a fallar
set -euo pipefail

# Se va a detener el proceso si una comprobacion falla, ademas imprime en pantalla la linea donde ocurrio el problema
trap 'echo "ERROR en linea $LINENO. Revisar los registros de salida." >&2' ERR

# Ubicar la raiz del proyecto a partir de la ubicacion del script
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_dir"

# Definir las rutas de las herramientas incluidas en el contenedor
gem5="/opt/gem5/build/ARM_MESI/gem5.opt"
config="/opt/gem5/configs/deprecated/example/se.py"
libm5="/opt/gem5/util/m5/build/arm64/out/libm5.a"

# Permitir una carpeta alternativa para repetir la validacion correspondiente. Ademas, si no se recibe un argumento, utilizar la carpeta de forma predeterminada
# Si hay mas de un argumento el IF se activa y se muestra un uso incorrecto
if (( $# > 1 )); then
	#Imprimir mensaje en pantalla del uso incorrecto
	echo "Uso: bash scripts/test_gemm_sve.sh [carpeta_salida]" >&2
    exit 1
fi

#Asigna la carpeta de salida. Si se paso un argumento, lo utiliza, sino usa la predeterminada
out="${1:-results/validation/gemm_sve_suite}"

# Comprobar que las herramientas necesarias esten disponibles
# Itera sobre el compilador ARM, el desensamblador y Python3
for herramienta in aarch64-linux-gnu-gcc aarch64-linux-gnu-objdump python3; do
	# command -v verifica si el programa existe
    command -v "$herramienta" >/dev/null
done

# Comprobar la existencia de loss archivos necesarios para compilar y simular
test -x "$gem5"
test -f "$config"
test -f "$libm5"
test -f /opt/gem5/include/gem5/m5ops.h
test -f src/gemm_sve.c

# Crear una carpeta nueva para los resultados
# Si ya existe, detenerse para conservar las evidencias anteriores
mkdir -p -- "$(dirname -- "$out")"

# El IF se activa cuando la carpeta ya existe
if ! mkdir -- "$out"; then
	# Imprime en pantalla el error, para no sobreescribir ningun resultado anterior
    echo "No se pudo crear $out. Si ya existe, usa otra carpeta." >&2
    exit 1
fi

# Convierte la ruta de salida a una ruta absoluta
out=$(cd -- "$out" && pwd)
# Imprime en pantalla la ruta de donde se guardan los resultados
echo "Resultados: $out"

# Conservar el programa y el script utilizados en esta ejecucion
# Las copias permiten revisar posteriormente como se hizo la prueba
# La siguiente linea copia el codigo fuente
cp src/gemm_sve.c "$out/gemm_sve.c"
# Copia este script
cp "$project_dir/scripts/test_gemm_sve.sh" "$out/test_gemm_sve.sh"

# Genera un hash (SHA256) del codigo fuente y lo guarda
sha256sum src/gemm_sve.c > "$out/source.sha256"
# Guarda la version del compilador actual
aarch64-linux-gnu-gcc --version > "$out/compiler.txt"
# Guarda la informacion de construccion del simulador gem5
"$gem5" --build-info > "$out/gem5_build_info.txt" 2>&1

# Crear un nombre independiente para el ejecutable de esta validacion
# El archivo queda dentro de bin/, pero no se incluye en Git (.gitignore)
mkdir -p bin
binary=$(mktemp "$project_dir/bin/gemm_sve_validation_XXXXXX")

# Compilar una sola vez
# Las 16 pruebas utilizaran exactamente el mismo ejecutable
# Definir el array con todos los argumentos necesarios para compilar el codigo, que se muestran a continuacion:
# 1-> aarch64-linux-gnu-gcc: el compilador cruzado para ARM64
# 2-> -std=c11 -O2 -static: usa estandar C11, optimizacion nivel 2, y enlazado estatico (sin dependencias dinamicas)
# 3-> -Wall -Wextra -Wpedantic: activa todas las advertencias posibles para un codigo limpio
# 4-> -march=armv8-a+sve: indica a GCC que genere codigo para la arquitectura ARMv8-A con soporte SVE habilitado
# 5-> -msve-vector-bits=scalable: indica que el tamano del vector SVE es escalable (dinamico) y no es fijo
# 6-> -fno-tree-vectorize: evita que el compilador vectorice bucles automaticamente
# 7-> -fno-tree-slp-vectorize: forzar que se evalue unicamente la vectorizacion manual que se le dio
# 8-> -ffp-contract=off: desactiva instrucciones FMA automaticas para control matematico
# 9-> -DUSE_GEM5: define una macro de preprocesador para el codigo C
# 10-> -I/opt/gem5/include: incluye la carpeta de cabeceras de gem5
# 11-> "$out/gemm_sve.c": archivo fuente a compilar
# 12-> "$libm5": enlaza la biblioteca m5
# 13-> -lm: enlaza la biblioteca matematica estandar (libm)
# 14-> -o "$binary": especifica el archivo de salida
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
    "$out/gemm_sve.c"
    "$libm5"
    -lm
    -o "$binary"
)

# Guardar el comando de compilacion y ejecutar el mismo
printf '%q ' "${compilar[@]}" > "$out/build_command.txt"
printf '\n' >> "$out/build_command.txt"

# Ejecuta el comando de compilacion
"${compilar[@]}" > "$out/build.log" 2>&1


# Guardar el formato del archivo binario generado, el hash y el ensamblado del ejecutable
file "$binary" > "$out/binary_info.txt"
sha256sum "$binary" > "$out/binary.sha256"

# Desensambla el codigo del binario y guarda el codigo ensamblador en "kernel_asm.txt"
aarch64-linux-gnu-objdump \
    -d --disassemble=gemm_sve \
    "$binary" \
    > "$out/kernel_asm.txt"

# Comprobar que el kernel (codigo ensamblador) contiene multiplicacion y suma vectoriales SVE
grep -Eq 'fmul[[:space:]]+z[0-9]+\.s' "$out/kernel_asm.txt"
grep -Eq 'fadd[[:space:]]+z[0-9]+\.s' "$out/kernel_asm.txt"



# Ejecutar las pruebas una por una
# N=17 comprueba el manejo de grupos incompletos de columnas.
# Incializar el contador de corridas exitosas
corridas=0

# Inicia un bucle para el tamaño de la matriz N
for n in 16 17; do
	# Incia un bucle para la longitud SVE (este analisis va en bloques de 128 bits)
    for vl in 128 256 384 512 640 768 896 1024; do

        # gem5 recibe la longitud vectorial en unidades de 128 bits
        unidades=$((vl / 128))

        # Calcula cuantos elementos tipo float (32 bits) caben en el vector actual
        elementos=$((vl / 32))

        # Crear una carpeta independiente para esta combinacion en especifico
        corrida="$out/n${n}_vl${vl}"
        mkdir "$corrida"

       # Mensaje en pantalla que indica que se esta iniciando
        echo "Ejecutando N=$n VL=$vl"

        # Preparar el comando de simulacion
        # TimingSimple se utiliza aqui para comprobar funcionamiento
        # 1->"$gem5": ejecutable del simulador
        # 2-> -d "$corrida": directorio de salida para esta simulacion en especifica
        # 3-> "$config": script de configuracion
        # 4-> --cpu-type=ArmO3CPU: tipo de procesador a simular (CPU ARM fuera de orden)
        # 5-> --num-cpus=1: se realiza la simulacion con un solo nucleo
        # 6-> --caches: activar caches L1
        # 7-> --l2cache: activar cache L2
        # 8-> --mem-size=512MiB: asignar 512 MB de memoria RAM simulada
        # 9-> --param "system.cpu[0].isa[0].sve_vl_se=$unidades": se indica el parametro que ajusta el tamano del vector SVE en el CPU
        # 10-> -c "$binary": binario que se va a ejecutar dentro del simulador
        # 11-> -o "$n": argumento 'N' que es el tamano de la matriz

#=========================================================
# NOTA IMPORTANTE: utilizar ArmO3CPU para validar las operaciones SVE, porque TimingSimpleCPU aborto en VL=640 al dividir una lectura de memoria
# O3 dispone de otro manejo de solicitudes divididas y se verificaran todas las longitudes con este mismo modelo de CPU
#=========================================================
        comando=(
            "$gem5"
            -d "$corrida"
            "$config"
            --cpu-type=ArmO3CPU
            --num-cpus=1
            --caches
            --l2cache
            --mem-size=512MiB
            --param "system.cpu[0].isa[0].sve_vl_se=$unidades"
            -c "$binary"
            -o "$n"
        )

        # Conservar el comando exacto de gem5 en un archivo txt de esa corrida
        printf '%q ' "${comando[@]}" > "$corrida/command.txt"
        printf '\n' >> "$corrida/command.txt"

        # Ejecutar gem5 y guardar su codigo de salida
        # Si falla, conservar el registro para revisar el problema
        codigo=0
        "${comando[@]}" > "$corrida/run.log" 2>&1 || codigo=$?

		# Guarda el codigo de salida de gem5 en un archivo txt
        printf 'Codigo de salida: %s\n' "$codigo" \
            > "$corrida/exit_code.txt"

		# Si el codigo de salida no es 0 (hubo error de simulacion) se activa el IF
        if (( codigo != 0 )); then
        	# Impresion en pantalla del error
            echo "Fallo la simulacion. Revisar $corrida/run.log" >&2
            exit 1
        fi

        # Comprobar la longitud vectorial observada por el programa y que sea correcta
        grep -Fqx \
            "SVE VL_BITS=$vl ELEMENTOS_FLOAT=$elementos" \
            "$corrida/run.log"

        # Comprobar que todos los elementos coinciden con la referencia
        grep -Eq \
            "^N=$n CHECK=PASS errores=0 " \
            "$corrida/run.log"

        # Revisar la configuracion efectiva guardada por el simulador gem5
        grep -Eq \
            "^sve_vl_se=$unidades[[:space:]]*$" \
            "$corrida/config.ini"

		# Verifica que se haya generado correctamente el archivo config.json
        test -s "$corrida/config.json"

#----------------------------------------------------------------------------------------
        # Revisar el primer bloque de estadisticas mediante Python
        # Se entrega la ruta de stats.txt como argumento al codigo
        # El bloque debe estar completo y contener instrucciones y tiempo positivos
        python3 - "$corrida/stats.txt" <<'PY'


# Importar sys para recibir la ruta del archivo desde el script bash
import sys

# Importar path para abrir y leer el archivo de estadisticas
from pathlib import Path

# Leer todo el contenido del archivo indicado en el primer argumento
texto = Path(sys.argv[1]).read_text()

# Encontrar el inicio del primer bloque de estadisticas
inicio = texto.index("Begin Simulation Statistics")

# Encontrar el cierre de ese mismo bloque, buscando desde su inicio
fin = texto.index("End Simulation Statistics", inicio)

# Crear un diccionario para guardar los nombres y valores de las metricas
metricas = {}



# Recorrer cada linea del primer bloque de estadisticas
for linea in texto[inicio:fin].splitlines():
    # Separar la linea en columnas utilizando los espacios
    partes = linea.split()


    # Comprobar que existan al menos dos columnas
    # Guardar solamente instrucciones simuladas y tiempo en ticks
    if len(partes) >= 2 and partes[0] in ("simInsts", "simTicks"):

        # Convertir el valor a numero y asociarlo con el nombre de la metrica
        metricas[partes[0]] = float(partes[1])

# Esta comprobacion se realiza despues de terminar el bucle anterior
# La instruccion all() exige que ambas metricas sean mayores que cero
# La instruccion get(nombre, 0) devuelve 0 si una metrica no fue encontrada
if not all(
    metricas.get(nombre, 0) > 0
    for nombre in ("simInsts", "simTicks")
):
    # Detener la validacion si falta una metrica o su valor no es positivo
    raise SystemExit(
        "ERROR: el primer bloque no contiene metricas positivas."
    )
PY

#-------------------------------------------------------------------------------------------------

	    # Registrar el exito solamente cuando pasan las comprobaciones
        printf 'VALIDACION_SVE_OK N=%s VL_BITS=%s\n' "$n" "$vl" \
            > "$corrida/validation.txt"

		# Imprime en pantala el certificado de validacion para observar el progreso
        cat "$corrida/validation.txt"

		# Incrementar el contador de corridas exitosas
        corridas=$((corridas + 1))
    done
done

# Este resultado final se genera solo si terminan las 16 pruebas
printf 'VALIDACION_SVE_COMPLETA CORRIDAS=%s\n' "$corridas" \
    > "$out/validation.txt"

# Imprime el resultado final en la consola
cat "$out/validation.txt"
