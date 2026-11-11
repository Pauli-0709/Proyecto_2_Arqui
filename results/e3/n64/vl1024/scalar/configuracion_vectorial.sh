#!/usr/bin/env bash
# La proxima linea le indica al OS (kernel) que el archivo de texto debe ser ejecutado utilizando el interprete Bash

#=====================================================================================
# Configuracion comun del experimento E3 para el GEMM escalar y el GEMM SVE
# Este archivo se va a cargar desde ejecutar_vectorial.sh
# El lanzador valida previamente la variable vl_bits
#========================================================================================

# Definir el array con todas las opciones vectoriales para el simulador gem5
# 1-> --cpu-type=ArmO3CPU: define el modelo de CPU a utilizar, en este caso en particular un CPU Out-of-Order de arquitectura ARM
# 2-> --num-cpus=1: establece el numero de nucleos de CPU simulados en 1
# 3-> --cpu-clock=2GHz: configura la frecuencia de reloj de la CPU a una frecuencia de 2 GHz
# 4-> --sys-clock=1GHz: configura la frecuencia de reloj del sistema a una frecuencia de 1 GHz
# 5-> --caches: habilita el uso de caches de primer nivel en la simulacion (L1)
# 6-> --l2cache: habilita el uso de la cache de segundo nivel (L2)
# 7-> --l1i_size=32KiB: define el tamano de la cache de instrucciones L1 a 32 KiB
# 8-> --l1d_size=32KiB: define el tamano de la cache de datos L1 a 32 KiB
# 9-> --l2_size=256KiB: define el tamano de la cache L2 a 256 KiB
# 10-> --l1i_assoc=2: establece la asociatividad de la cache de instrucciones L1 a 2 vias
# 11-> --l1d_assoc=2: establece la asociatividad de la cache de datos L1 a 2 vias
# 12-> --l2_assoc=8: establece la asociatividad de la cache L2 a 8 vias
# 13-> --cacheline_size=64: configura el tamano de la linea de cache a 64 bytes
# 14-> --mem-type=DDR3_1600_8x8: especifica el tipo de memoria principal como DDR3 a una frecuencia de 1600 MHz
# 15-> --mem-size=512MiB: asigna un tamano de 512 MiB a la memoria principal
opciones_vectoriales=(
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


# Mantener todas las etapas con ancho 2
# Este for itera sobre los distintos parametros de las etapas del procesador
for parametro in \
    fetchWidth decodeWidth renameWidth dispatchWidth \
    issueWidth wbWidth commitWidth
do
	# Agrega un nuevo parametro al arreglo de configuraciones
    opciones_vectoriales+=(--param "system.cpu[0].${parametro}=2")
done

# Estructuras del procesador constantes durante el experimento E3
# 1-> --param "system.cpu[0].numROBEntries=192": establece el numero de entradas del ROB a 192
# 2-> --param "system.cpu[0].numIQEntries=64": define el tamano de la Instruction Queue (IQ) a 64 entradas
# 3-> --param "system.cpu[0].forwardComSize=256": establece el tamano de las comunicaciones hacia adelante a 256
opciones_vectoriales+=(--param "system.cpu[0].numROBEntries=192" --param "system.cpu[0].numIQEntries=64" --param "system.cpu[0].forwardComSize=256")

# El simulador gem5 expresa VL en unidades de 128 bits
# Se configura tambien al ejecutar el programa escalar
# --param "system.cpu[0].isa[0].sve_vl_se=$((vl_bits / 128))": divide los bits del vector entre 128 y los asigna al parametro SVE VL del procesador
opciones_vectoriales+=(--param "system.cpu[0].isa[0].sve_vl_se=$((vl_bits / 128))")
