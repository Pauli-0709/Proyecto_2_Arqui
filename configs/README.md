# Configuraciones de gem5

En esta carpeta contiene las diversas configuraciones de simulacion desarrolladas por el equipo de trabajo.


## Configuracion implementada para E1

El script `scripts/ejecutar_linea_base.sh` ejecuta el mismo GEMM escalar con un nucleo en los modelos: `ArmTimingSimpleCPU`,
`ArmMinorCPU` y `ArmO3CPU`. Asimismo, se prueban matrices de tamano de N=64 y de N=128, para un total de 6 corridas.

La configuracion se carga desde `scripts/lib_evidencia.sh`:

- CPU a una frecuencia de 2 GHz y reloj del sistema a una frecuencia de 1 GHz.
- Caches L1I y L1D de 32 KiB y 2 vias cada una de ellas.
- Cache L2 de 256 KiB y 8 vias.
- Lineas de cache de 64 bytes.
- Memoria DDR3_1600_8x8 de 512 MiB por defecto.

Desde la raiz del repositorio en Ubuntu, con la imagen Docker instalada en el pc, reproducir el siguiente comando para reproducir
el experimento E1:

```bash
bash scripts/arm_env.sh bash scripts/reproducir_e1.sh
```

Es importante mencionar que el comando ejecuta y valida las 6 corridas, genera el archivo CSV de metricas y el grafico de IPC y ciclos
correspondiente y guarda las salidas en la ruta `.local/e1.XXXXXX`.

Finalmente, los resultados oficiales generados para el experimento y su posterior interpretacion estan en el [informe de E1](../report/e1.md).


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

Por otro lado, los detalles de ejecucion y del ajuste utilizado estan en
[la documentacion del experimento E2](../docs/experimento_superescalar.md).

Finalmente, desde la raiz del repositorio, se debe ejecutar el siguiente comando: `bash scripts/arm_env.sh bash scripts/reproducir_e2.sh`. Este script
verifica las 24 corridas cuando ya estan publicadas y ejecuta las configuraciones cuyas carpetas faltan. Asimismo, el script regenera los 2 archivos CSV
y los 2 graficos. A su vez, el resumen correspondiente de ocupacion de IQ y de ROB usa las muestras guardadas en la ruta `results/e2/ocupacion/`. Por ultimo, el
[analisis de E2](../docs/experimento_superescalar.md) explica los diversos resultados y el alcance de esa ventana de medicion en especifico.

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

En cuarto lugar, las 32 corridas para los tamanos de N=64 y de N=128 estan publicadas en la siguiente ruta: `results/e3/`. Asimismo, la extraccion de metricas y el
calculo del speedup estan completados, con los CSV disponibles en la siguiente ruta: `results/e3/summary/`. De la misma manera, el grafico de speedup frente a VL
se encuentra en la siguiente ruta: `results/e3/figures/`, en formatos PNG y SVG. 

En quinto lugar, el experimento E3 ya esta completado. A su vez, el [analisis y las conclusiones de E3](../docs/experimento_vectorial.md#conclusiones-del-experimento-e3)
incluyen la comparacion de los diversos contadores de la memoria memoria. Asimismo la [seccion de reproduccion del README principal](../README.md#reproducir-e3-con-un-solo-comando)
tiene como objetivo indicar como ejecutar el barrido completo y como poder regenerar los archivos CSV y las distintas figuras a partir de las corridas publicadas
en el repositorio.

Finalmente, los distintos resultados de las simulaciones que se llevaron a cabo se guardan en la ruta `results/`.
