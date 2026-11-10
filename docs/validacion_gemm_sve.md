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
