#!/usr/bin/env bash

# Esta seccion va a detener el script ante algun posible error o variables que no estan definidas
set -euo pipefail


#--------------------------------------------------------------------------------------------------------
raiz=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) # Busca la raiz del repositorio
cd "$raiz" # Utiliza esta raiz como la carpeta de trabajo para este script
gem5=/opt/gem5 # Se localiza el simulador gem5 en la imagen del equipo
configuracion="$gem5/configs/deprecated/example/se.py" # Se utiliza la configuracion SE
biblioteca="$gem5/util/m5/build/arm64/out/libm5.a" # Se localizan las marcas de la region de interes para este script
mkdir -p bin # Se prepara la carpeta de archivos locales
salida=$(mktemp -d "$raiz/bin/prueba_falso_compartido.XXXXXX") # Se genera una carpeta nueva por cada una de las pruebas
echo "SALIDA=$salida" # Muestra en pantalla donde quedan los registros

fuente=src/falso_compartido.c # Selecciona el programa que se va a probar (falso_compartido.c)
opciones=(-std=c11 -O2 -Wall -Wextra -Werror -fopenmp) # Se comparte las opciones de compilacion
gcc "${opciones[@]}" "$fuente" -o "$salida/nativo" # Se realiza la compilacion para la maquina que ejecuta el Docker
arm=(-static -DUSE_GEM5 "-I$gem5/include") # Se activa el enlace estatico y las marcas de simulador geme5
aarch64-linux-gnu-gcc "${opciones[@]}" "${arm[@]}" "$fuente" "$biblioteca" -o "$salida/arm" # Se compila para AArch64

hilos=2 # Se van a utilizar 2 hilos y 2 nucleos para la prueba funcional
iteraciones=1000 # Se decidio utilizar 1000 incrementos por hilo para que la prueba sea corta y no se extienda demasiado
modos=(sin_relleno con_relleno) # Prueba ambas distribuciones de la memoria


#------------------------------------------------------------------------------------------------------------------------------
for modo in "${modos[@]}"; do # Primero se valida ambos modos en nativo
    "$salida/nativo" "$hilos" "$modo" "$iteraciones" | tee "$salida/nativo_$modo.log" # Se realiza y se guarda el resultado nativo
done

for protocolo in MESI MOESI; do # Segundo se prueba las 2 versiones de Ruby del equipo
    simulador="$gem5/build/ARM_$protocolo/gem5.opt" # Se selecciona el ejecutable de cada uno de los protocolo

    for modo in "${modos[@]}"; do # Tercer se simula cada distribucion con el mismo protocolo seleccionado
        corrida="$salida/${protocolo}_$modo" # Se separa los resultados por protocolo y modo
        mkdir "$corrida" # Se genera la carpeta de esta corrida
        echo "PROBANDO $protocolo $modo" # Se muestra en pantalla la corrida que esta en curso
        cpu=(--ruby --cpu-type=ArmTimingSimpleCPU "--num-cpus=$hilos" --cacheline_size=64 --mem-size=512MiB) # Se configura el  Ruby y los 2 nucleos


        if ! "$simulador" -d "$corrida" "$configuracion" "${cpu[@]}" -c "$salida/arm" -o "$hilos $modo $iteraciones" > "$corrida/run.log" 2>&1; then # Se simula el programa en cuestion
            tail -n 30 "$corrida/run.log" >&2 # Se muesta el error si el simulador gem5 se detiene
            exit 1 # Se sale al fallar una corrida
        fi


        esperado="HILOS=$hilos HILOS_USADOS=$hilos MODO=$modo ITERACIONES=$iteraciones ESPERADO=$((hilos * iteraciones)) CHECK=PASS errores=0" # Se genera el resultado esperado
        if ! grep -Fx "$esperado" "$corrida/run.log"; then # If para comprobar los contadores y los hilos usados
            tail -n 30 "$corrida/run.log" >&2 # Se muestra el registro en cuestion si falta la confirmacion
            exit 1 # Termina con error si el programa no pasa
        fi


        bloques=$(grep -c 'End Simulation Statistics' "$corrida/stats.txt" || true) # Variable que cuenta los bloques completos
        if (( bloques < 2 )); then # If para comprobar el volcado de la ROI y el volcado final
            echo "Faltan bloques de estadisticas en $corrida/stats.txt" >&2 # Se indica en pantalla el archivo a revisar
            exit 1 # Termina la ejecucion si falta evidencia de la medicion
        fi


    done
done

echo "VALIDACION_FALSO_COMPARTIDO_OK CORRIDAS_GEM5=4" # Mensaje final, que confirma que pasaron las 4 simulaciones
