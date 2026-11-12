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
- Un validation.txt no vacio en cada carpeta de corrida.
- Un run.log que contenga CHECK=PASS y errores=0.

A su vez, el script utiliza solamente bibliotecas incluidas en Python. No necesita ejecutar el Docker ni repetir ninguna de las simulaciones.

## 4. Metricas extraidas

| Columna | Significado |
| --- | --- |
| ruta | Ruta del archivo stats.txt de origen |
| roi_block | Numero del bloque seleccionado: 1 |
| simInsts | Instrucciones de la ROI |
| system.cpu.numCycles | Ciclos del nucleo |
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
- Evidencias de validacion ausentes o vacias.
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

Esta version extrae las metricas basicas de las corridas actuales de un nucleo de los experimentos E2 y E3.

Para E3 permanecen pendientes:

- Publicar los CSV definitivos.
- Separar N, VL y programa en columnas.
- Calcular el speedup por pareja escalar/SVE.
- Elaborar los graficos y el analisis.
- Integrar la regeneracion de CSV y graficos en un comando.

Para el experimento E2 todavia deben incorporarse las metricas adicionales de IPC, ocupacion de IQ/ROB y prediccion requeridas por el enunciado.

