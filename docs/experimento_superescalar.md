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
- forwardComSize de 256, esta variable va a ser constante para las 24 corridas.

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

Asimismo, este comando corresponde a la prueba inicial con un tamano de N=16. A su vez, si la carpeta de salida ya existe, el script se detiene 
para evitar sobreescribi dicha carpeta. 

NOTA IMPORTANTE: para poder repetir esta prueba se debe utilizar una carpeta de salida nueva, si asi se requiere.

## Ejecucion del barrido completo

Los siguientes comandos se ejecutan desde la raiz del repositorio en Ubuntu, fuera del Docker. A su vez, el script arm_env.sh se encarga de 
ejecutar los comandos dentro del docker.

Asimismo, para poder ejecutar o verificar las 12 configuraciones de cada tamano se debe seguir los siguientes comandos:

```bash
bash scripts/arm_env.sh bash scripts/barrido_superescalar.sh 64 &&
bash scripts/arm_env.sh bash scripts/barrido_superescalar.sh 128
```

Es importante indicar que cada tamano combina los anchos 1, 2, 4 y 8 con los ROB de 32, 64 y 192 entradas. Las corridas se ejecutan una despues 
de otra.

De la misma manera, es importante indicar que tambien existe la posibilidad de que se puede realizar por bloques de 6 configuraciones:

```bash
bash scripts/arm_env.sh bash scripts/barrido_superescalar.sh 64 1 2
bash scripts/arm_env.sh bash scripts/barrido_superescalar.sh 64 4 8
bash scripts/arm_env.sh bash scripts/barrido_superescalar.sh 128 1 2
bash scripts/arm_env.sh bash scripts/barrido_superescalar.sh 128 4 8
```

Es importante el tener en cuenta que se debe esperar a que termine cada bloque antes de ejecutar el siguiente. NO ejecutar varios barridos 
simultaneamente en la misma carpeta del repositorio, porque utilizan el mismo ejecutable y genera un error.

A su vez, cuando se verifica el barrido completo de la simulacion realizada, se debe esperar los siguientes mensajes en pantalla:

```text
BLOQUE_COMPLETO N=64 CORRIDAS=12
BLOQUE_COMPLETO N=128 CORRIDAS=12
```

Por otra parte, si una carpeta de resultados ya existe, el script verifica sus archivos sin repetir la simulacion. Si esta carpeta no existe, 
realiza la ejecucion de la corrida y verifica el resultado generado. Asimismo, si encuentra una corrida incompleta o incompatible con los 
archivos actuales, el script la  detiene.

A su vez, como las 24 corridas ya estan publicadas en el repositorio del proyecto, al clonarlo y ejecutar estos comandos se verifican las 
evidencias existentes en el repositorio (pruebas ya realizadas).

Finalmente, para repetir una corrida se debe conservar primero su carpeta fuera de la carpte results/e2/ y volver a ejecutar el bloque 
correspondiente que asi se requiera.

## Estado de validacion

La configuracion fue validada con GEMM, teniendo en cuenta un N=16, un ancho 2 y un ROB de 64 entradas.

Asimismo, la prueba termino con el esperado mensaje de CHECK=PASS, con 0 errores y un error absoluto maximo igual a 0. Tambien se logro verificar
los parametros del procesador mediante config.ini.

Por otra parte, se generaron dos bloques de estadisticas: en primer lugar, el volcado de la region de interes y en segundo lugar el volcado final.

La evidencia de la prueba se observa en la siguiente ruta:
results/validation/superescalar_n16_ancho2_rob64/

Posteriorment, se aplico forwardComSize=256 y se verifico su presencia en el archivo config.ini para la configuracion utilizada: N=64, ancho=1 y 
ROB=64, que anteriormente abortaba (seccion "Incidencia importante para notificar durante el primer bloque del barrido"). 

Por otra parte, se completo el primer bloque del barrido: 6 configuraciones para N=64, teniendo en cuenta anchos de 1 y de 2 con un ROB de 32, 
64 y 192 entradas. 

El script verifico las 6 corridas y termino con el mensaje:

    BLOQUE_COMPLETO N=64 CORRIDAS=6

Asimismo, la configuracion que tiene un ancho=1 y un ROB=64 se reutilizo despues de superar las comprobaciones del barrido. Las otras 5
configuraciones se ejecutaron durante este bloque y terminaron con el mensaje esperado: CHECK=PASS, teniendo 0 errores y error absoluto maximo de 0.

Por ende, es importante mencionar que el fallo de TimeBuffer no volvio a aparecer en este bloque. La validacion del ajuste para las 
configuraciones restantes continua pendiente.

Evidencias: results/e2/n64/ancho1_rob*/ y
results/e2/n64/ancho2_rob*/.

Avance del barrido: 6 de 24 corridas verificadas.
La extraccion a CSV, el analisis y los graficos siguen pendientes.

## Incidencia importante para notificar durante el primer bloque del barrido

Al momento de generar e implementar el barrido para N=64 con anchos de 1 y 2, la configuracion ancho=1 y ROB=32 termino correctamente, con 
CHECK=PASS y 0 errores. Por otra parte, la siguiente configuracion, ancho=1 y ROB=64, se detuvo repentinamente dentro del simulador gem5
24.1.0.1 dando el siguiente mensaje mensaje:

    TimeBuffer<T>::valid(int)
    Assertion `idx >= -past && idx <= future' failed.

AL investigar el error senala directamente a la función IEW::instToCommit. A su vez, el barrido que se estaba ejecutando se detuvo y esta corrida
no se puede considerar como completada.

### Diagnostico y ajuste propuesto

Es importante mencionar que el fallo es compatible con un desbordamiento del bufer temporal el cual es utilizado para enviar resultados de IEW 
al commit. Utilizando un wbWidth=1, los resultados pendientes pueden necesitar de posiciones futuras que las mismas superen la capacidad 
predeterminada del bufer.

Asimismo, para poder comprobar este diagnostico, se propone establecer:

    --param "system.cpu[0].forwardComSize=256"

Este valor 256 es una decision de la configuracion puntual utilizada y dada por el equipo y no un requisito del enunciado del proyecto (html). 
Es importante mencionar que la eficacia de la misma se debe verificar mediante nuevas simulaciones.

Por otra parte, este parametro se mantendra fijo en las 24 corridas posteriores. A su vez, los anchos del pipeline seguiran tomando los 
valores de 1, 2, 4 y 8, el ROB tomara los valores de 32, 64 y 192 entradas y finalmente la IQ permanecera en 64 entradas.

### Conservación de evidencias y repetición

De la misma manera, los resultados del intento anterior se van a conservarar en la ruta .local/, separados del conjunto final.

Asimismo, tambien se debe repetir la configuracion que había terminado correctamente, esto con el fin de que  todas las corridas oficiales utilicen
la misma configuracion del bufer temporal propuesta en la seccion anterior.

