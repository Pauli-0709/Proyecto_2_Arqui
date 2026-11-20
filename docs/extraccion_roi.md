# Extraccion de estadisticas de la ROI

Responsable: Steven Loaiza

## 1. Objetivo

El objetivo principal es el de convertir los archivos stats.txt en una fila de CSV por corrida, siguiendo el apartado "Automatizar corridas y extraccion de metricas"
del enunciado del proyecto.

Asimismo el script utilizado se encuentra en la ruta `scripts/parse_stats.py`.

## 2. Seleccion de la ROI

Los programas actuales delimitan la multiplicacion mediante el uco de `m5_reset_stats(0, 0)` y `m5_dump_stats(0, 0)`.

Asimismo con estos programas y lanzadores, el primer bloque completo del archivo stats.txt corresponde al volcado de la ROI. A su vez, el extractor selecciona
ese bloque en particular e ignora los posteriores, que incluyen trabajo adicional.

Por otra parte, esta seleccion debe revisarse si se modifica la instrumentacion o se agregan volcados anteriores a la ROI. El actual script no identifica
automaticamente que bloque corresponde al kernel.

## 3. Requisitos

- Python 3.
- Un archivo stats.txt o una carpeta que contenga esos archivos.
- En el modo original se va a exiger un `validation.txt` con contenido por cada corrida. Asimismo, con `--solo-globales`, la validacion se comprueba en `run.log`.
- Un run.log que contenga CHECK=PASS y errores=0.

A su vez, el script utiliza solamente bibliotecas incluidas en Python. No necesita ejecutar el Docker ni repetir ninguna de las simulaciones.

## 4. Metricas extraidas

| Columna | Significado |
| --- | --- |
| ruta | Ruta del archivo stats.txt de origen |
| roi_block | Numero del bloque seleccionado: 1 |
| simInsts | Instrucciones de la ROI |
| system.cpu.numCycles | Ciclos del nucleo. Esta columna aparece en el modo original |
| simTicks | Ticks simulados durante la ROI |
| simFreq | Ticks por segundo simulado |
| roi_seconds | Tiempo simulado calculado como simTicks / simFreq |

Asimismo, el tiempo corresponde al sistema simulado, no al tiempo que tarda el simulador gem5 en ejecutarse en la computadora.

## 5. Uso

Los comandos se ejecutan desde la raiz del repositorio, en la consola de Linux.

### Comprobar la sintaxis

```bash
# Verificar que el archivo Python tiene sintaxis valida.
python3 -m py_compile scripts/parse_stats.py
```

### Procesar una corrida

```bash
# Extraer las metricas de una corrida escalar.
python3 scripts/parse_stats.py results/e3/n64/vl128/scalar/stats.txt
```

### Procesar una pareja escalar y SVE

```bash
# Extraer las dos corridas de N=64 y VL=128.
python3 scripts/parse_stats.py results/e3/n64/vl128
```

### Procesar todas las corridas de E3

```bash
# Extraer las 32 corridas publicadas de E3.
python3 scripts/parse_stats.py results/e3
```

Por otra parte, el CSV se imprime en la salida estandar, stdout. Los mensajes de comprobacion o error se imprimen en stderr.

De la misma manera, para las 32 corridas completas, el mensaje esperado es:

```text
EXTRACCION_OK CORRIDAS=32 BLOQUE_ROI=1
```

### Procesar corridas con varios nucleos

La opcion `--solo-globales` extrae `simInsts`, `simTicks` y `simFreq` del primer bloque del archivo `stats.txt`. A su vez, esta tambien calcula 
`roi_seconds` como `simTicks / simFreq`. Asimismo, cada una de las corridas debe tener el mensaje de `CHECK=PASS errores=0` en el archivo `run.log`.

```bash
# Se extraen las metricas de GEMM paralelo con cuatro hilos.
python3 scripts/parse_stats.py --solo-globales results/validation/gemm_paralelo_n16.BJhgEJ/hilos_4

# Se extraen las metricas de falso compartido con MESI y sin relleno.
python3 scripts/parse_stats.py --solo-globales results/validation/falso_compartido_n2.0e1qLs/MESI_sin_relleno
```

Finalmente cada uno de los comandos genera una fila de CSV y muestra en pantalla el mensaje: `EXTRACCION_OK CORRIDAS=1 BLOQUE_ROI=1`.


### Guardar un CSV de prueba

```bash
# Crear una carpeta temporal para conservar la prueba.
prueba_roi=$(mktemp -d)

# Conservar el CSV solamente si la extraccion termina correctamente.
if python3 scripts/parse_stats.py results/e3 > "$prueba_roi/e3_roi.tmp"; then
    mv "$prueba_roi/e3_roi.tmp" "$prueba_roi/e3_roi.csv"
    printf 'CSV de prueba: %s\n' "$prueba_roi/e3_roi.csv"
fi
```

## 6. Comprobaciones del extractor

El script va a rechazar:

- Entradas inexistentes o carpetas sin archivos stats.txt.
- Archivos `validation.txt` ausentes o vacios cuando se va a utilizar el modo original.
- Registros sin CHECK=PASS y errores=0.
- Un primer bloque de estadisticas incompleto.
- Metricas requeridas ausentes o duplicadas.
- Valores no numericos, no finitos, no enteros o no positivos.

De la misma forma, todas las corridas se procesan antes de imprimir el encabezado y las filas. Si alguna de estas falla, el script termina con codigo 1 sin emitir 
un CSV parcial.

Estas comprobaciones no sustituyen la revision del hardware, los comandos de compilacion y la instrumentacion de la ROI.

## 7. Valores de referencia para comprobar la extraccion

Las corridas publicadas para el tamano de N=64 y el VL=128 contienen los siguientes valores en el primer bloque:

| Programa | simInsts | system.cpu.numCycles | simTicks |
| --- | --- | --- | --- |
| scalar | 1876497 | 1120451 | 560225500 |
| sve | 535062 | 410856 | 205428000 |

Estos valores permiten contrastar la salida del extractor contra los archivos originales.

## 8. Alcance y pendientes

El modo original logra extraer las diversas metricas basicas de las corridas de un nucleo de los experimentos E2 y E3. La opcion `--solo-globales` logra extraer las
instrucciones y el tiempo simulado del primer bloque. Esto se comprobo con corridas de GEMM paralelo y de falso compartido.

A su vez, para el experimento E3 ya se implemento el procesamiento de las 32 corridas mediante el script de la ruta `scripts/resumir_e3.py`.

Asimismo el script genera lo siguiente:

- `results/e3/summary/e3_metricas.csv`: 32 corridas con N, VL y programa.
- `results/e3/summary/e3_speedup.csv`: 16 comparaciones escalar/SVE.

Para regenerar ambos archivos se debe ejecutar:

```bash
python3 scripts/resumir_e3.py # Extraer las metricas y calcular el speedup de E3.
```

Por otra parte, el speedup principal se calcula como el tiempo escalar dividido entre tiempo SVE. A su vez, tambien se calcula la razon de ciclos como comprobacion
de consistencia para las parejas con igual frecuencia.

Por otra parte, el procesamiento reutiliza el primer bloque de ROI y las comprobaciones de `scripts/parse_stats.py`. Asimismo, se exige las 32 rutas esperadas y verifica
la confirmacion individual de cada programa, N y VL.

Por otra parte, las comprobaciones del script no sustituyen la revision del hardware registrado en config.ini.

Fnalmente, los graficos y el analisis del experimento E3 estan disponibles en el [documento del experimento vectorial](experimento_vectorial.md). Ademas, los CSV y las figuras 
correspondientes se pueden volver a regenerar desde las corridas guardadas con el comando: `bash scripts/arm_env.sh bash scripts/reproducir_e3.sh`.

Para el experimento E2 todavia deben incorporarse las metricas adicionales de IPC, ocupacion de IQ/ROB y prediccion requeridas por el enunciado.

