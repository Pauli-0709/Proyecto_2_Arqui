#=========================================================================================================
# SCRIPT barrido_superescalar.sh

#=========================================================================================================


#La proxima linea le indica al OS (kernel) que el archivo de texto debe ser ejecutado utilizando el interprete Bash
#!/usr/bin/env bash

#Configuracion utilizada:
# 1) e: sale inmediatamente si cualquier comando falla (esta va a devolver un codigo != 0)
# 2) u: trata el uso de variables no definidas como un error
# 3) o pipefail: hace que una tubería falle si cualquiera de sus distintos subcomandos llega a fallar
set -euo pipefail

#Determina la carpeta del proyecto
raiz=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$raiz"


#Verifica que exista al menos un argumento (N) y si no muestra un mensaje de error en pantalla
if (($# < 1)); then
    echo "Uso: bash scripts/barrido_superescalar.sh N [ANCHOS...]" >&2
    exit 1
fi

#Se toma N del primer argumento enviado
n=$1
shift


#Verifica la dimension de las matrices
#NOTA ACLARATORIA: el script ejecutar_superescalar.sh admite cualquier tamano N de matriz, pero el barrido solo admite N=64 y N=128
case "$n" in
    64|128) ;;
    *) echo "N debe ser 64 o 128." >&2; exit 1 ;;
esac


#Verifica si se especifica los anchos, sino es asi se reemplazan los parametros por el barrido completo (1, 2, 4 y 8)
if (($# == 0)); then
    set -- 1 2 4 8
fi

#Se almacen los anchos (anteriores parametros) en un arreglo para iterar sobre estos
anchos=("$@")

#Se validan todos los anchos antes de iniciar cualquier tipo de simulacion, evitando de esta manera el detecta un valor invalido a mitad de un barrido
for ancho in "${anchos[@]}"; do
    case "$ancho" in
        1|2|4|8) ;;
        *) echo "Ancho no permitido: $ancho" >&2; exit 1 ;;
    esac
done



#verificar_corrida CARPETA N ANCHO ROB
#Verifica que los datos correspondan a la configuracion solicitada y a la version actual del codigo
verificar_corrida() (
    set -euo pipefail

#carpeta -> directorio o ruta de los resultados
#tamano -> dimension N de las diversas matrices
#ancho_cpu -> ancho del pipeline
#entradas_rob -> numero de entradas del ROB
    carpeta=$1
    tamano=$2
    ancho_cpu=$3
    entradas_rob=$4

#Verifica que todos los datos esperados existan y no esten vacios
    for archivo in \
        stats.txt config.ini config.json command.txt \
        run.log validation.txt source.sha256 binary.sha256 \
        compiler.txt binary_info.txt gem5_build_info.txt \
        kernel_asm.txt configuracion_superescalar.sh \
        ejecutar_superescalar.sh
    do
        test -s "$carpeta/$archivo"
    done

#Un build.log vacio es valido si no hubo advertencias
    test -f "$carpeta/build.log"

#Comprobar que validation.txt llegue a contener exactamente la linea de validacion que corresponde a la configuracion dada
    grep -Fxq \
        "VALIDACION_SUPERESCALAR_OK N=$tamano ANCHO=$ancho_cpu ROB=$entradas_rob" \
        "$carpeta/validation.txt"
#Verificacion funcional, puesto que el programa simulado debe dar un resultado de CHECK=PASS y que no tenga errores, para la dimension N
    grep -Eq \
        "^N=$tamano CHECK=PASS errores=0([[:space:]]|$)" \
        "$carpeta/run.log"
#Verifica que la simulacion termino de forma exitosa
    grep -q "because exiting with last active thread context" \
        "$carpeta/run.log"

#Evitar mezclar resultados de distintas versiones del programa
    sha256sum --check "$carpeta/source.sha256" >/dev/null

#SVerifica que la configuración y el script archivados en la corrida sean idénticos a la version actual
    cmp -s configs/configuracion_superescalar.sh \
        "$carpeta/configuracion_superescalar.sh"

    cmp -s scripts/ejecutar_superescalar.sh \
        "$carpeta/ejecutar_superescalar.sh"

#Esta seccion de codigo genera una verificacion en python de la configuracion realizada en gem5 y de las estadisticas
#Los argumentas son la ruta de la corrida realizada, el ancho esperado y el tamano del ROB puntual
    python3 - "$carpeta" "$ancho_cpu" "$entradas_rob" <<'PY'
import configparser
import pathlib
import sys

#Parametros recibidos desde Bash (ancho y ROB se convierten a enteros)
ruta = pathlib.Path(sys.argv[1])
ancho, rob = map(int, sys.argv[2:])

#Lectura del archivo config.ini
config = configparser.ConfigParser(interpolation=None)
config.optionxform = str
config.read(ruta / "config.ini")
cpu = config["system.cpu"]

#Se verifica que el modelo de CPU sea el de ejecucion fuera de orden
assert cpu["type"] == "BaseO3CPU"

#Verificar que todas las etapas del pipeline deben tener el ancho dado
for parametro in (
    "fetchWidth", "decodeWidth", "renameWidth",
    "dispatchWidth", "issueWidth", "wbWidth", "commitWidth"
):
    assert int(cpu[parametro]) == ancho, parametro

#Verificar el tamano del ROB y el tamano fijo de la cola de instrucciones (IQ)
assert int(cpu["numROBEntries"]) == rob
assert int(cpu["numIQEntries"]) == 64

# Verificar que el primer bloque de estadisticas este completo y contenga ciclos positivos
texto = (ruta / "stats.txt").read_text()
inicio = texto.index("---------- Begin Simulation Statistics ----------")
fin = texto.index("---------- End Simulation Statistics", inicio)
bloque = texto[inicio:fin]

metricas = {}
for linea in bloque.splitlines():
    campos = linea.split()
    if len(campos) >= 2 and not linea.startswith("-"):
        metricas[campos[0]] = campos[1]

#Verificar que la simulacion haya sido ejecuitado los diversos ciclos y instruccciones
assert float(metricas["system.cpu.numCycles"]) > 0
assert float(metricas["simInsts"]) > 0
PY
)

#COntador de corridas verificadas
comprobadas=0

# Barrido principal: ancho del pipeline x tamaño del ROB
for ancho in "${anchos[@]}"; do
    for rob in 32 64 192; do
        salida="results/e2/n${n}/ancho${ancho}_rob${rob}"


#Si la corrida ya existe solo se verifica, sino se simula
#Esta comprobacion evita sobreescribir evidencia previa, puesto que el script ejecuta_superescalar.sh rechaza las carpetas existentes
#===============================================================================================================
#IMPORTANTE: Una corrida incompleta falla la verificacion y se debera eliminarse manualmente antes de repetirla
#============================================================================================================
        if [[ -e "$salida" ]]; then
            echo "Revisando corrida existente: $salida"
        else
            echo "Ejecutando N=$n ANCHO=$ancho ROB=$rob"
            bash scripts/ejecutar_superescalar.sh \
                "$n" "$ancho" "$rob" "$salida"
        fi

#Se ejecuta como comando independiente y cualquier fallo detiene el barrido por set -e.
        verificar_corrida "$salida" "$n" "$ancho" "$rob"

        echo "CORRIDA_VERIFICADA N=$n ANCHO=$ancho ROB=$rob"
        comprobadas=$((comprobadas + 1))
    done
done

#Mensaje final en pantalla, que indica el bloque de corridas para el N en especifico se completo y cuantos valores de configuraciones se lograron
#verificar (anchos x 3 valores del ROB)
echo "BLOQUE_COMPLETO N=$n CORRIDAS=$comprobadas"
