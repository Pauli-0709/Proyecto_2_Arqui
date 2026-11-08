#=====================================================================================================================
#Script de Compilacion y Validacion para Multiplicacion de Matrices (GEMM Escalar- gemm_scalar.c)
#==================================================================================================================

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

#Define el directorio de salida para los registros y artefactos de la validacion
out="results/validation/gemm_scalar_native"

#Genera los directores necesarios (los bin para los ejecutables y los outs para los logs)
mkdir -p bin "$out"

#Guardar informacion de el contexto de la misma para poder y garantizar la reproduccion del experimento
gcc --version > "$out/compiler.txt"
sha256sum src/gemm_scalar.c > "$out/source.sha256"


#El siguiente bloque compila el codigo fuente asegurando un entorno escalar puro y determinista, teniendo en cuenta los siguientes factores:
# 1) std=c11 -O2: utiliza el estandar C11 con un nivel de optimizacion moderado
# 2) Wall -Wextra -Wpedantic: activa advertencias estrictas para calidad de codigo
# 3) fno-tree-vectorize / -fno-tree-slp-vectorize: desactivan la vectorizacion automatica (SIMD)
# 4) ffp-contract=off: desactiva la contraccion de operaciones de punto flotante (FMA) para asegurar precision numerica exacta
# 5) src/gemm_scalar.c: especifica el archivo de codigo fuente en C que sera compilado
# 6) -lm: enlaza la biblioteca matematica estandar de C (libm)
# 7) -o bin/gemm_scalar_native: define la ruta y nombre del archivo ejecutable resultante (bin/gemm_scalar_native)
# 8) 2>&1 | tee "$out/build.log": redirige tanto la salida estandar como los errores (2>&1) hacia el comando tee, el a su vez imprime todo en pantalla y lo guarda en build.log
gcc -std=c11 -O2 \
    -Wall -Wextra -Wpedantic \
    -fno-tree-vectorize \
    -fno-tree-slp-vectorize \
    -ffp-contract=off \
    src/gemm_scalar.c \
    -lm \
    -o bin/gemm_scalar_native \
    2>&1 | tee "$out/build.log"



#Se realizan las distintas pruebas funcionales con diferentes tamanos pequenos de matrices (N)
#Los bucles for se iteran sobre 3 tamanos distintos de matrices: N=16, N=64 y N=128
#./bin/gemm_scalar_native "$n": ejecuta el bin compilado pasandole al mismo el argumento (n)
#2>&1 | tee "$out/n${n}.log": captura la salida y errores de la ejecucion, los muestra en la consola y los guarda en el archivo log
#grep -q "CHECK=PASS errores=0" "$out/n${n}.log": busca sobre el log de la prueba en cuestion "-q", la cual refleja que la paso con exito la prueba, sino la encuentra la instruccion grep falla y detiene el script debido a lao configuracion del inicio del script "set -e" 
for n in 16 64 128; do
    ./bin/gemm_scalar_native "$n" \
        2>&1 | tee "$out/n${n}.log"
    grep -q "CHECK=PASS errores=0" "$out/n${n}.log"
done


#Prueba de caso critico: N=0 debe ser rechazado de forma obligatoria (ejecuta el programa con n=0, redirige su salida al log de errores y evalua el mismo, si el tiene exito debe imprimir un mensaje de error en la consola)
if ./bin/gemm_scalar_native 0 > "$out/n0_invalido.log" 2>&1; then
    echo "ERROR: el programa acepto N=0."
    exit 1
#Si el programa falla como se esperaba, se va a capturar su codigo de salida y se registra
else
    codigo=$?
    printf 'Codigo de salida: %s\n' "$codigo" \
        >> "$out/n0_invalido.log"
#Se verifica que el mensaje dado por el programa sea el esperado
    grep -q "N debe ser un entero" "$out/n0_invalido.log"
#Fin del if
fi

#Mensaje final de exito si todas la pruebas que fueron efectuadas pasaron satifactoriamente los distintos tests
echo "Pruebas nativas completadas correctamente."
