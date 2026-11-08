# =======================================================================================
# Script de Compilación Cruzada ARM64 y Simulacion Arquitectonica en GEM5
# ===================================================================================

#Objetivo: el objetivo es el poder automatizar la compilacion estatica de gemm_scalar.c para Aarch64 utilizando el compilador cruzado GCC, asi
#como el poder enlazar las librerias de control m5ops del simulador gem5 y el poder generar el codigo desensamblado. Finalmente corre la simulacion
#en gem5 (se.py) con un modelo de CPU detallado y jerarquias de chaches


#La proxima linea le indica al OS (kernel) que el archivo de texto debe ser ejecutado utilizando el interprete Bash
#!/usr/bin/env bash

#Configuración utilizada:
# 1) e: sale inmediatamente si cualquier comando falla (esta va a devolver un codigo != 0)
# 2) u: trata el uso de variables no definidas como un error
# 3) o pipefail: hace que una tubería falle si cualquiera de sus distintos subcomandos llega a fallar
set -euo pipefail


#En el siguiente comando se va a ubicar de forma dinamica en la raiz del repositorio basandose en la ubicacion del script
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_dir"

#Definicion de rutas del entorno de simulacion de gem5 y directorios de salida
gem5="/opt/gem5/build/ARM_MESI/gem5.opt"
config="/opt/gem5/configs/deprecated/example/se.py"
libm5="/opt/gem5/util/m5/build/arm64/out/libm5.a"
out="results/validation/gemm_scalar_n16"


#Verificar que existan las herramientas necesarias, como, lo son los prerequisitos como la comprobacion de la existencia y permisos de diversos ejecutables, scripts de configuracion, librerias estaticas y cabeceras
test -x "$gem5"
test -f "$config"
test -f "$libm5"
test -f /opt/gem5/include/gem5/m5ops.h


#Genera los directores necesarios (los bin para los ejecutables y los outs para los logs)
mkdir -p bin "$out"

#Guardar informacion de el contexto de la misma para poder y garantizar la reproduccion del experimento
#Obtiene la versión del compilador cruzado ARM de 64 bits y la guarda en el archivo 'compiler.txt'
aarch64-linux-gnu-gcc --version > "$out/compiler.txt"
sha256sum src/gemm_scalar.c > "$out/source.sha256"


#El siguien bloque ejecuta la compilación cruzada del programa en C para arquitectura ARM64 (AArch64), teniendo en cuenta los siguientes factores:
# 1) std=c11 -02: se utiliza el estándar C11 y se aplica un nivel de optimizacion moderada
# 2) static: este genera un binario completamente estatico (crucial en SE mode de gem5)
# 3) Wall -Wextra -Wpedantic: activa advertencias estrictas para la calidad del codigo
# 4) fno-tree-vectorize / -fno-tree-slp-vectorize: desactivan la vectorización automatica (SIMD)
# 5) ffp-contract=off: desactiva la contraccion de operaciones de punto flotante (FMA) para asegurar precision numerica exacta
# 6) DUSE_GEM5: Activa las directivas de preprocesador para llamadas especiales al simulador gem5
# 7) I/opt/gem5/include: anade la ruta de cabeceras de gem5 (m5ops.h)
# 8) src/gemm_scalar.c: especifica el archivo de codigo fuente en C que sera compilado
# 9) "$libm5": enlaza la librería de m5
# 10) -lm: enlaza la biblioteca matematica estandar de C (libm)
# 11) -o bin/gemm_scalar: define la ruta y nombre del archivo ejecutable resultante (bin/gemm_scalar)
# 8) 2>&1 | tee "$out/build.log": redirige tanto la salida estandar como los errores (2>&1) hacia el comando tee, el a su vez imprime todo en pantalla y lo guarda en build.log
aarch64-linux-gnu-gcc \
    -std=c11 -O2 -static \
    -Wall -Wextra -Wpedantic \
    -fno-tree-vectorize \
    -fno-tree-slp-vectorize \
    -ffp-contract=off \
    -DUSE_GEM5 \
    -I/opt/gem5/include \
    src/gemm_scalar.c \
    "$libm5" \
    -lm \
    -o bin/gemm_scalar \
    2>&1 | tee "$out/build.log"


#Registra el formato y hash del ejecutable
file bin/gemm_scalar | tee "$out/binary_info.txt"
sha256sum bin/gemm_scalar > "$out/binary.sha256"

#El siguiente bloque extrae el codigo en lenguaje ensamblador exclusivamente de la función gemm_scalar  utilizando la instruccion objdump para 
#verificar manualmente que la misma no contenga instrucciones vectoriales
aarch64-linux-gnu-objdump \
    -d --disassemble=gemm_scalar \
    bin/gemm_scalar \
    > "$out/kernel_asm.txt"

#Evita el confundir archivos de una prueba previa con la ejecucion actual
rm -f "$out/stats.txt" "$out/config.ini" "$out/config.json"


#EL siguente bloque ejecuta la simulación funcional y del rendimiento dentro del simulador gem5 teniendo en cuenta un tamano de matriz de N = 16, y los siguientes factores:
# 1) -d: directorio de salida para los archivos de estadisticas y configuracion del simulador gem5
# 2) --cpu-type=ArmTimingSimpleCPU: este contiene el modelo de procesador detallado basado en ciclos
# 3) --num-cpus=1: configura un unico nicleo para el procesamiento
# 4) --caches --l2cache: habilita la jerarquía de memoria cache L1 (I/D) y L2
# 5) --mem-size=512MiB: se le asigna 512 MiB de memoria fisica simulada
# 6) -c "$project_dir/bin/gemm_scalar": ruta del binario ejecutable compilado para ARM
# 7) -o 16: argumento pasado al programa emulado (este es el argumento para el definir el tamano de la matriz N=16)
# 8) 2>&1 | tee "$out/run.log": redirige tanto la salida estandar como los errores (2>&1) hacia el comando tee, el a su vez imprime todo en pantalla y lo guarda en run.log
"$gem5" \
    -d "$project_dir/$out" \
    "$config" \
    --cpu-type=ArmTimingSimpleCPU \
    --num-cpus=1 \
    --caches \
    --l2cache \
    --mem-size=512MiB \
    -c "$project_dir/bin/gemm_scalar" \
    -o 16 \
    2>&1 | tee "$out/run.log"

#Comprobar que el resultado del programa y los distintos archivos de salida, teniendo en cuenta el run.log
grep -q "N=16 CHECK=PASS errores=0" "$out/run.log"

#Comprobar que el simulador gem5 haya generado correctamente todos los archivos de salida obligatorios
test -s "$out/stats.txt"
test -s "$out/config.ini"
test -s "$out/config.json"

#Verificar la integridad del archivo de estadísticas (stats.txt) del simulador gem5 asegurando su cabecera.
grep -q "Begin Simulation Statistics" "$out/stats.txt"

#Mensaje final de exito si todas la pruebas que fueron efectuadas pasaron satifactoriamente los distintos tests
echo "Validacion ARM en gem5 completada correctamente."
