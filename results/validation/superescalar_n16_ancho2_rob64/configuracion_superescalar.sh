#Objetivo principal: este archivo puntual se va a cargar desde ejecutar_superescalar.sh. Asimismo, el script principal valida las variables de
#ancho y rob

#Indica que el script debe ejecutarse usando el intérprete bash
#!/usr/bin/env bash

#=================================================================================================================================
#CONFIGURACION BASE DEL PROCESADOR Y MEMORIA
#================================================================================================================================
#El siguiente bloque va a inicializar el arreglo que contiene la configuracion base para simular un procesador especifico y su jerarquia de memoria
#en el simulador gem5, teniendo en cuenta los siguientes factores:
# 1) --cpu-type=ArmO3CPU: utiliza un modelo de CPU especifico de ARM con una ejecucion fuera de orden para poder simular las arquitecturas avanzadas
# 2) --num-cpus=1: simula un procesador de un solo nucleo
# 3) --cpu-clock=2GHz / --sys-clock=1GHz: establece una frecuencia de reloj de la CPU a 2 GHz y del bus del sistema a una frecuencia de un 1 GHz
# 4) --caches / --l2cache: activa el uso de caches de nivel #1 (conocida como L1) y de nivel #2 (conocida como L2)
# 5) --l1i_size=32KiB / --l1d_size=32KiB: va a  definir el tamano de las caches L1 tanto la de instrucciones como la de datos en 32 KB en cada una de ellas
# 6) --l2_size=256KiB: pone el tamano de la cache L2 unificada en 256 KiB
# 7) --l1i_assoc=2 / --l1d_assoc=2 / --l2_assoc=8: configura la asociatividad de las caches, la cual se  asigna a  2 vías para la L1 y 8 vías para la L2
# 8) --cacheline_size=64: pone el tamano de las líneas de cache en 64 bytes
# 9) --mem-type=DDR3_1600_8x8 / --mem-size=512MiB: configura las caracteristicas de la memoria principal, usando una de tipo DDR3 a una frecuencia de 1600 MHz y una capacidad total de 512 MiB
opciones_procesador=(
    --cpu-type=ArmO3CPU
    --num-cpus=1
    --cpu-clock=2GHz
    --sys-clock=1GHz
    --caches
    --l2cache
    --l1i_size=32KiB
    --l1d_size=32KiB
    --l2_size=256KiB
    --l1i_assoc=2
    --l1d_assoc=2
    --l2_assoc=8
    --cacheline_size=64
    --mem-type=DDR3_1600_8x8
    --mem-size=512MiB
)

#=========================================================================================================================
# 2. CONFIGURACION DEL "ANCHO" SUPERESCALAR
#========================================================================================================================
#El siguiente bloque de instrucciones va a ajustar el ancho de todas las etapas del pipeline del CPU para que sea coherente, especificamente para
#una ejecucion superescalar, teniendo en cuenta los siguientes factores:
# 1) for parametro in...: va a iterar sobre las etapas criticas del CPU, como lo son: el fetch, el decode, el rename, el dispatch, el issue, el writeback o el commit
# 2) opciones_procesador+=(--param "system.cpu[0].${parametro}=${ancho}"): concatena los distintos parametros al arreglo y los sobreescribe
for parametro in \
    fetchWidth decodeWidth renameWidth dispatchWidth \
    issueWidth wbWidth commitWidth
do
    opciones_procesador+=(--param "system.cpu[0].${parametro}=${ancho}")
done


#==============================================================================================================================
# 3. CONFIGURACION DE LAS ESTRUCTURAS FUERA DE ORDEN
#===============================================================================================================================
#Se anaden los parametros que controlan el tamano de las colas de instrucciones, en otras palabras se va a variar el ROB y mantener constante
#la cola de instrucciones
opciones_procesador+=(
    --param "system.cpu[0].numROBEntries=${rob}"
    --param "system.cpu[0].numIQEntries=64"
)

#NOTA: el ROB es crucial para mantener el estado de las instrucciones que se ejecutan fuera de orden
