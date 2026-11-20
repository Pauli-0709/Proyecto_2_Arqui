# Validacion funcional de GEMM SVE

## Objetivo

En primer lugar, se va a comprobar que GEMM SVE calcula de forma correcta la multiplicacion de matrices C = A x B para diferentes longitudes vectoriales.

En segundo lugar, cada elemento del resultado se va a comparar contra una referencia calculada utilizando variables tipo double, fuera de la region de interes.

## Configuracion utilizada

- gem5 24.1.0.1.
- Ejecutable estatico AArch64 con instrucciones SVE.
- Un nucleo ArmO3CPU.
- Caches L1 y L2 habilitadas.
- Memoria simulada de 512 MiB.
- Tamanos de matriz: N=16 y N=17.
- Longitudes vectoriales: 128, 256, 384, 512, 640, 768, 896 y 1024 bits.
- Asimismo el mismo ejecutable se utiliza en las 16 corridas.

## Resultados

Las 16 corridas que fueron ejecutadas terminaron con una impresion en pantalla de CHECK=PASS, 0 errores y un error absoluto maximo igual a 0.

| Tamano | Corridas correctas | Checksum |
| --- | --- | --- |
| N=16 | 8 de 8 | -2.8203125 |
| N=17 | 8 de 8 | 2.4296875 |

Por otra parte, para un tamano de N=17 permite poder comprobar el manejo de grupos incompletos de columnas para las longitudes vectoriales evaluadas en el experimento.

## Ajuste del modelo de CPU

En primer lugar, la validacion inicial utilizo el ArmTimingSimpleCPU la cual paso para un tamano de N=16 con VL de 128, 256, 384 y 512 bits.

En segundo lugar, al ejecutar VL=640 bits, el simulador gem5 aborto con un codigo de 134 en pantalla y se debio a una asercion en TimingSimpleCPU::initiateMemRead,
la cual esta relacionada directamente con la division de una lectura de memoria.

Por la anterior razon, se cambio el modelo a un ArmO3CPU y se volvieron a repetir las 16 combinaciones en una carpeta nueva. Finalmente, todas estas pruebas pasaron.

## Evidencias

Los resultados completos se encuentran en:

results/validation/gemm_sve_suite_o3/

Asimismo. esta carpeta conserva el codigo y el script utilizados, como los datos de compilacion, el ensamblado y una carpeta por cada una de las corridas con
configuracion, estadisticas, comando, registro y validacion.

## Reproduccion

Desde la raiz del repositorio, entrar al contenedor:

```bash
bash scripts/arm_env.sh
```

Dentro del contenedor, ejecutar con una carpeta que no exista

```
cd /work
bash scripts/test_gemm_sve.sh \
  results/validation/gemm_sve_suite_o3_repeticion1
```

Finalmente, el resultado final esperado es:

VALIDACION_SVE_COMPLETA CORRIDAS=16

## Validacion funcional con QEMU

Es importante mencionar que ninguno de los integrantes del equipo disponia de un procesador ARM64 con soporte para instrucciones SVE. Por esa razon, se decidio utilizar
QEMU en Ubuntu x86_64 para de esta manera poder ejecutar el programa GEMM SVE con matrices de 16 por 16 y comprobar su resultado fuera del simulador gem5.

La prueba reporto un mensaje de `CHECK=PASS` y 0 errores al comparar la multiplicacion con el resultado de la referencia. Asimismo, la ejecucion se realizo mediante 
emulacion y la validacion nativa utilizando hardware ARM64 con SVE quedo como un pendiente. Por otra parte, la prueba en el simulador gem5 se conserva como parte de la 
validacion del proyecto.

[Evidencia de la prueba con N=16](../results/validation/gemm_sve_qemu/n16.log)

### Como repetir la prueba con el uso del emulador QEMU

En Ubuntu x86_64, se instalan las herramientas necesarias con el siguiete comando: `sudo apt install qemu-user gcc-aarch64-linux-gnu libc6-dev-arm64-cross`. Continuamente,
desde la raiz del repositorio, se debe ejecutar los siguientes comandos:

```bash
# Se crea una carpeta temporal para esta repeticion
salida_qemu=$(mktemp -d) &&

# Se compila el programa ARM64 con soporte para SVE
aarch64-linux-gnu-gcc -std=c11 -O2 -static -march=armv8-a+sve -msve-vector-bits=scalable -ffp-contract=off src/gemm_sve.c -lm -o "$salida_qemu/gemm_sve" &&

# Se ejecuta la prueba con un tamano de N=16 y se guarda la salida
qemu-aarch64 -cpu max "$salida_qemu/gemm_sve" 16 > "$salida_qemu/n16.log" 2>&1 &&

# Se muestran la longitud vectorial y el resultado de la prueba ejecutada
cat "$salida_qemu/n16.log"
```

La prueba se considera correcta cuando aparece en pantalla el mensaje de `N=16 CHECK=PASS errores=0`. Asimismo, la longitud vectorial que fue utilizada se muestra en la linea
`SVE VL_BITS=`. Ademas, en la corrida publicada se registraron 512 bits.
