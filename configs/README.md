# Configuraciones de gem5

En esta carpeta contiene las diversas configuraciones de simulacion desarrolladas por el equipo de trabajo.

## Configuracion implementada para E2

EN primer lugar, el archivo configuracion_superescalar.sh contiene los parametros utilizados para el experimento superescalar.

A su vez, este archivo es cargado por scripts/ejecutar_superescalar.sh, que recibe el tamano especifico de la matriz, el ancho, el ROB y la 
carpeta de salida. Por ende, no es necesario ejecutar la configuracion por separado.

Asimismo, se modifican conjuntamente fetchWidth, decodeWidth, renameWidth, dispatchWidth, issueWidth, wbWidth y commitWidth, utilizando los distintos
anchos de 1, 2, 4 y 8. A su vez, el ROB toma valores de 32, 64 y 192 entradas.

Los parametros constantes son los siguientes:

- Un nucleo ArmO3CPU a una frecuecia de 2 GHz.
- Frecuencia del sistema de un 1 GHz.
- IQ de 64 entradas.
- L1I y L1D de 32 KiB y 2 vias respectivamente.
- L2 de 256 KiB y 8 vias.
- Lineas de cache de 64 bytes.
- Memoria DDR3_1600_8x8 con rango de 512 MiB.
- forwardComSize=256.

De la misma manera, se utilizan caches clasicas y se.py de gem5 24.1.0.1.

Por otra parte, el barrido de E2 esta completado: las 12 configuraciones para el tamano de N=64 y 12 configuraciones para el tamano de N=128. 
Las evidencias estan en la carpeta results/e2/.

Se verifican desde la raiz del repositorio en Ubuntu, fuera del Docker, y se pueden ejecutar o analizar las existentes con el barrido del 
siguiente comando:

```bash
bash scripts/arm_env.sh bash scripts/barrido_superescalar.sh 64 &&
bash scripts/arm_env.sh bash scripts/barrido_superescalar.sh 128
```

Por otra parte, si las carpetas ya existen, el barrido debe verificar sus evidencias sin repetir ninguna de las simulaciones. A su vez, si estas
no existen, debe ejecutar las corridas respectivas.

Finalmente, los detalles de ejecucion y del ajuste utilizado estan en
[la documentacion del experimento E2](../docs/experimento_superescalar.md).

## Configuracion implementada para E3

Responsable: Steven Loaiza

EN primer lugar, el archivo: `configuracion_vectorial.sh` va a definir el hardware comun para las versiones escalar y SVE. Ademas, este esta cargado por el siguiente
script: `scripts/ejecutar_vectorial.sh`.

En segundo lugar, la configuracion utilizada es la siguiente:

- Un nucleo ArmO3CPU a 2 GHz y reloj del sistema a una frecuencia de 1 GHz.
- Ancho 2 en fetch, decode, rename, dispatch, issue, writeback y commit.
- ROB de 192 entradas e IQ de 64 entradas.
- L1I y L1D de 32 KiB y a 2 vias.
- L2 de 256 KiB y a 8 vias.
- Lineas de cache de 64 bytes.
- Memoria DDR3_1600_8x8 con rango de 512 MiB.
- forwardComSize=256.

En tercer lugar, la longitud vectorial se configura mediante `sve_vl_se`, y la misma es expresada en unidades de 128 bits. Asimismo, para cada VL se utiliza el mismo 
hardware en las ejecuciones escalar y SVE.

En cuarto lugar, las 32 corridas para un tamano de N=64 y de N=128 estan publicadas en la siguiente ruta: `results/e3/`. La extraccion a CSV, los graficos y el 
analisis permanecen pendientes.


## Pendientes

- Configuracion para E1: TimingSimple, Minor y O3.

E2 utiliza GEMM escalar con N=64 y N=128. Estos mismos tamanos estan previstos para el experimento E1.

Es importante mencionar que cada configuracion debera documentar CPU, frecuencia, caches, memoria y paremetros modificados. Los diversos parametros
que no formen parte del barrido deberan mantenerse constantes y quedar registrados.

Finalmente es fundamental indicar que los resultados de las distintas simulaciones se guardan en la ruta de results/ y no en esta carpeta.
