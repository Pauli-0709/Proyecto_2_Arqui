#======================================================================================================================================
# FUNCIONAMIENTO DEL SCRIPT

# 1) Revisa que se le de los parametros de forma correcta, los 4 datos: N (tamano de matriz), el ancho, el ROB y el lugar de salida
# 2) Compila el programa de C que multiplica las matrices (GEMM) para ARM
# 3) Corre el programa dentro del simulador gem5, teniendo en cuenta un procesador superescalar con una configuracion especifica de
#    ancho y ROB puntual
# 4) Guarda los diversos archivos generados (logs, versiones, entre otras)
# 5) Finalmente comprueba el resultado, que el mismo sea correcto y que la configuracion que se le brindo al CPU sea la misma
#======================================================================================================================================

#La proxima linea le indica al OS (kernel) que el archivo de texto debe ser ejecutado utilizando el interprete Bash
#!/usr/bin/env bash

#Configuracion utilizada:
# 1) e: sale inmediatamente si cualquier comando falla (esta va a devolver un codigo != 0)
# 2) u: trata el uso de variables no definidas como un error
# 3) o pipefail: hace que una tubería falle si cualquiera de sus distintos subcomandos llega a fallar
set -euo pipefail


#Busca la ruta del proyecto
directorio_proyecto=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$directorio_proyecto"

#Verificar el numero de argumentos, si no es correcto imprime un mensaje en pantalla de como se debe colocar (explicacion de la llamada) y genera
#el mensaje de error
if [[ $# -ne 4 ]]; then
    echo "Uso: bash scripts/ejecutar_superescalar.sh N ANCHO ROB SALIDA" >&2
    exit 1
fi


#Asignacion de los diversos argumentos a variables definidas
#tamano -> N: las matrices son de N x N
#ancho -> ancho del pipeline (fetch, decode, rename, dispatch, issue, writeback y commit)
#rob -> capacidad del Reorder Buffer - ROB (permite ejecucion fuera de orden con retiro en orden)
#salida -> directorio de resultados
tamano=$1
ancho=$2
rob=$3
salida=$4


#Validacion de los parametros
#Dimension de las distintas matrices
case "$tamano" in
    16|64|128) ;;
    *) echo "N debe ser 16, 64 o 128." >&2; exit 1 ;;
esac

#Ancho del pipline
case "$ancho" in
    1|2|4|8) ;;
    *) echo "El ancho debe ser 1, 2, 4 u 8." >&2; exit 1 ;;
esac

#Tamano del ROB
case "$rob" in
    32|64|192) ;;
    *) echo "El ROB debe ser 32, 64 o 192." >&2; exit 1 ;;
esac

#La carpeta de salida debe verificarse que este dentro de la carpte results/ y no puede tener "..", esto se penso asi para que ningun integrante
#del grupo de trabajo guarde archivos fuera de la ruta o carpeta del proyecto por error
if [[ "$salida" != results/* || "$salida" == *..* ]]; then
    echo "La salida debe estar dentro de results/, sin '..'." >&2
    exit 1
fi

#Esta verificacion es por si la carpeta ya existe, para evitar sobreescribir resultados previos y poder mantener la evidencia de otros experimentos
if [[ -e "$salida" ]]; then
    echo "La carpeta ya existe: $salida" >&2
    echo "Usa otra carpeta para conservar la evidencia anterior." >&2
    exit 1
fi


#Rutas de las distintas herramientas que se van a utilizar
#simulador -> simulador gem5 teniendo una version ARM
#configuracion -> script de gem5
#biblioteca -> biblioteca m5ops
#ejecutable -> ejecutable que resulta de la compilacion
simulador=/opt/gem5/build/ARM_MESI/gem5.opt
configuracion=/opt/gem5/configs/deprecated/example/se.py
biblioteca=/opt/gem5/util/m5/build/arm64/out/libm5.a
ejecutable=bin/gemm_superescalar

#Verifica si todo existe antes de iniciar, si algo hace falta el script se detiene en este punto
test -x "$simulador"
test -f "$configuracion"
test -f "$biblioteca"
test -f src/gemm_scalar.c


#Carga el archivo con la configuracion del procesador o CPU superescalar
source configs/configuracion_superescalar.sh

#Crea los directorios o carpetas bin (ejecutable) y salida
mkdir -p bin "$salida"

#Registrar compilador y fuentes utilizadas
#Se almacena la version del compilador cruzado y el hash SHA-256 del codigo fuente, lo que a su vez permite verificar posteriormente la integridad
#y la version del codigo empleado
aarch64-linux-gnu-gcc --version > "$salida/compiler.txt"
sha256sum src/gemm_scalar.c > "$salida/source.sha256"


#Conservar la configuracion y el script utilizados
cp configs/configuracion_superescalar.sh "$salida/"
cp scripts/ejecutar_superescalar.sh "$salida/"



#Compilar GEMM escalar para ARM con las operaciones m5, teniendo en cuenta una compilacion cruzada a Aarch64 y los siguientes factores:
# 1) -std=c11 -O2: estandar C11 con optimizacion nivel 2
# 2) -static: es un enlace estatico, coloca las librerias
# 3) -Wall -Wextra -Wpedantic: habilitan advertencias adicionales y verificacion estricta del estandar
# 4) -fno-tree-vectorize / -fno-tree-slp-vectorize: prohinir al compilador usar instrucciones vectoriales para que el programa sea escalar
# 5) -ffp-contract=off: impide la contraccion multiplicacion-suma en instrucciones FMA (no juntarla operacion multiplicar+sumar en una sola
#                       instruccion), para de esta manera  preservar el redondeo de cada operacion en punto flotante y la consistencia de los resultados
# 6) -DUSE_GEM5: habilitar en el codigo fuente (codigo en C) el uso de las operaciones m5
# 7) -I/opt/gem5/include: ruta de los encabezados de gem5 (donde buscar los .h de gem5)
# 8) -lm: enlaza la biblioteca matematica estandar
# 9) -o "$ejecutable": nombre del ejecutable de salida
# 10) "2>&1 | tee": muestra los mensajes en pantalla y los guarda en el build.log
aarch64-linux-gnu-gcc \
    -std=c11 -O2 -static \
    -Wall -Wextra -Wpedantic \
    -fno-tree-vectorize \
    -fno-tree-slp-vectorize \
    -ffp-contract=off \
    -DUSE_GEM5 \
    -I/opt/gem5/include \
    src/gemm_scalar.c "$biblioteca" \
    -lm -o "$ejecutable" \
    2>&1 | tee "$salida/build.log"


#Registra el hash SHA-256 del ejecutable y su formato (arquitectura, enlace, entre otros)
sha256sum "$ejecutable" > "$salida/binary.sha256"
file "$ejecutable" > "$salida/binary_info.txt"

#Desensambla la funcion gemm_scalar. Esto se efectua con el fin de poder observar y analizar codio generado para el kernel y verificar que no se
#utilizaron instrucciones vectoriales
aarch64-linux-gnu-objdump \
    -d --disassemble=gemm_scalar \
    "$ejecutable" > "$salida/kernel_asm.txt"

#Registrar la informacion de compilacion del simulador (la version, la variante y las diversas opciones)
"$simulador" --build-info > "$salida/gem5_build_info.txt"


#Construccion del arreglo con los parametros para el simulador gem5
comando=("$simulador" -d "$directorio_proyecto/$salida" "$configuracion" "${opciones_procesador[@]}" -c "$directorio_proyecto/$ejecutable" -o "$tamano")


#Registrar el comando exacto, esto con el fin de poder reproducir la simulacion de forma identica
printf '%q ' "${comando[@]}" > "$salida/command.txt"
printf '\n' >> "$salida/command.txt"


#Ejecutar la simulacion y conservar su salida, la salida se muestra en la consola y se almacena en el run.log
"${comando[@]}" 2>&1 | tee "$salida/run.log"


#VALIDACION DE LA SIMULACION REALIZADA
#La verificacion indica que el programa simulado debe indicar que el resultado de la multiplicacion es correcto (con un CHECK=PASS) y no indicar
#ningun error para la dimension N dada
grep -q "N=$tamano CHECK=PASS errores=0" "$salida/run.log"

#Se verifica que el simulador gem5 genero los archivos de salida y que los mismos no esten vacios
test -s "$salida/stats.txt"
test -s "$salida/config.ini"
test -s "$salida/config.json"

#Verificar los parametros guardados por el simulador gem5
python3 - "$salida/config.ini" "$ancho" "$rob" <<'PY'
import configparser
import sys

#Parametros recibidos desde el script
ruta, ancho, rob = sys.argv[1:]

configuracion = configparser.ConfigParser(interpolation=None)
configuracion.optionxform = str
configuracion.read(ruta)

cpu = configuracion["system.cpu"]

# ArmO3CPU hereda el tipo BaseO3CPU en esta version de gem5.
assert cpu["type"] == "BaseO3CPU", cpu["type"]

#Se verifica que la ISA de la CPU sea ARM
isas = cpu["isa"].split()
assert isas, "No se encontro la ISA del procesador"
for isa in isas:
    assert configuracion[isa]["type"] == "ArmISA"

#Se verifica que todas las etapas del pipeline deben tener el ancho solicitado (fetch (búsqueda), decode (decodificación),
#rename (renombrado de registros), dispatch (despacho), issue (emisión), wb (escritura de resultados) y commit (retiro de instrucciones))
for parametro in (
    "fetchWidth", "decodeWidth", "renameWidth", "dispatchWidth",
    "issueWidth", "wbWidth", "commitWidth"
):
    assert int(cpu[parametro]) == int(ancho), (
        parametro, cpu[parametro]
    )

#Se verifica el tamano del ROB solicitado y la cola de instrucciones (IQ)
assert int(cpu["numROBEntries"]) == int(rob)
assert int(cpu["numIQEntries"]) == 64

#Imprime en pantalla si todas las verificaciones se cumplen y la configuracion es la esperada
print("CONFIGURACION_SUPERESCALAR_OK")
PY

#Impresion en pantalla de validacion
echo "VALIDACION_SUPERESCALAR_OK N=$tamano ANCHO=$ancho ROB=$rob" \
    | tee "$salida/validation.txt"
