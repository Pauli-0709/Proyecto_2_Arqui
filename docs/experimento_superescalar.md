# Experimento E2: arquitectura superescalar

## Objetivo

El objetivo principal es el de poder evaluar el efecto del ancho del nucleo O3 y del tamano del ROB sobre el GEMM escalar. Asimismo, analizar
donde se llega a saturar el IPC y sus distintas causas.

## Variables y caracteristicas para el experimento

- Ancho: 1, 2, 4 y 8.
- ROB: 32, 64 y 192 entradas.
- Tamano de las matrices: N=64 y N=128.
- Total: 12 configuraciones por tamano y 24 corridas en total.

N=16 se utiliza únicamente para pruebas iniciales.

## Configuracion utilizada

Archivo y ruta de donde se ubica: configs/configuracion_superescalar.sh.

Se reutiliza el comando configs/deprecated/example/se.py de gem5 24.1.0.1. (Ejemplo de prueba del enunciado)

Asimismo, se modifican conjuntamente el fetchWidth, el decodeWidth, el renameWidth, el dispatchWidth, el issueWidth, el wbWidth y el commitWidth.

Parametros constantes:

- Un nucleo de ArmO3CPU a una frecuencia de 2 GHz.
- IQ de 64 entradas.
- L1I y L1D de 32 KiB y 2 vias.
- L2 de 256 KiB y 8 vias.
- Líneas de cache de 64 bytes.
- Memoria DDR3_1600_8x8 de 512 MiB.

A su vez, estos valores constantes son decisiones del equipo. Por otra parte, los demas parametros conservan los distintos  valores de gem5 y los
mismos quedan registrados en los archivos config.ini y config.json.

De la misma manera, se utilizan caches clasicas. FInalmente, tambien es importante mencionar que al ejecutar ARM_MESI no implica que esta prueba 
utilice Ruby ni valide una coherencia de multinucleo.

## Comparabilidad

Mantener el mismo programa, datos y opciones de compilacion. Asi como, el desactivar la autovectorizacion y la contraccion de las operaciones flotantes.
Tambien es importante el no modificar las caches, la frecuencia ni el IQ entre las distintas configuraciones.

## Región de interes

Es importante mencionar que las metricas deben corresponder a la region delimitada por m5_reset_stats() y m5_dump_stats().

A su vez, con el programa actual y sin volcados adicionales, el primer bloque de estadísticas corresponde y refleja al volcado de la ROI. Asimismo,
el volcado final puede incluir la verificacióo posterior.

Finalmente, es importante indicar que el reiniciar las diversas estadisticas no vacía las caches.

## Ejecucion de una configuracion

Dentro del Docker:

```bash
cd /work
bash scripts/ejecutar_superescalar.sh \
    16 2 64 \
    results/validation/superescalar_n16_ancho2_rob64
```
## Estado

La configuracion fue validada con GEMM, teniendo en cuenta un N=16, un ancho 2 y un ROB de 64 entradas.

Asimismo, la prueba termino con el esperado mensaje de CHECK=PASS, con 0 errores y un error absoluto maximo igual a 0. Tambien se logro verificar
los parametros del procesador mediante config.ini.

Por otra parte, se generaron dos bloques de estadisticas: en primer lugar, el volcado de la region de interes y en segundo lugar el volcado final.

La evidencia de la prueba se observa en la siguiente ruta:
results/validation/superescalar_n16_ancho2_rob64/

Finalmente, el barrido oficial de las 24 corridas para N=64 y N=128 y su posterior analisis siguen pendientes.
