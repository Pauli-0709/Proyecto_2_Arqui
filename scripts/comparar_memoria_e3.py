# Seccion de las bibliotecas
import csv	# Importar las herramientas para leer y escribir CSV
import io	# Importar un buffer para preparar todo el CSV antes de guardarlo
import sys	# Importar la salida de errores y el codigo de terminacion
from decimal import Decimal, InvalidOperation	# Importar numeros decimales y su error de conversion
from pathlib import Path	# Importar las rutas de archivos
from parse_stats import extraer_fila, INICIO, FIN	# Reutilizar la validacion existente y los delimitadores de la ROI

# Localizar la raiz independientemente del directorio de ejecucion
RAIZ = Path(__file__).resolve().parents[1]
# Definir exclusivamente el CSV derivado de esta comparacion
SALIDA = RAIZ / "results/e3/summary/e3_memoria_n128_vl512_vs_vl640.csv"


# Definir los contadores y la tasa que se comparam.
METRICAS = (
    # Instrucciones ejecutadas dentro de la ROI.
    "simInsts",
    # Ciclos de CPU dentro de la ROI.
    "system.cpu.numCycles",
    # Accesos de demanda de la cache de datos L1.
    "system.cpu.dcache.demandAccesses::total",
    # Fallos de demanda de la cache de datos L1.
    "system.cpu.dcache.demandMisses::total",
    # Tasa de fallos expresada como razon entre 0 y 1.
    "system.cpu.dcache.demandMissRate::total",
    # Eventos de acceso bloqueado por la cache.
    "system.cpu.lsq0.blockedByCache",
    # Eventos de bloqueo de rename por cola de cargas llena.
    "system.cpu.rename.LQFullEvents",
    # Fallos de demanda totales de L2, incluidos datos e instrucciones.
    "system.l2.demandMisses::total",
)


#-----------------------------------------------------------------------------------------------------------------
# Funcion auxiliar
# Leer y validar una corrida antes de aceptar sus metricas
def leer_memoria(vl):
    # Seleccionar la corrida SVE para un tamano de N=128
    ruta = RAIZ / f"results/e3/n128/vl{vl}/sve/stats.txt"
    # Verificar el archivo validation.txt, con CHECK=PASS y el primer bloque completo
    extraer_fila(ruta)
    # Leer el archivo original sin modificarlo
    texto = ruta.read_text(encoding="utf-8")
    # Aislar el primer bloque que ya valido el extractor existente
    bloque = texto.split(INICIO, 1)[1].split(FIN, 1)[0]
    # Crear el diccionario de valores encontrados
    valores = {}



    # Recorrer solamente las lineas de la ROI
    for linea in bloque.splitlines():
        # Eliminar comentarios y separar las columnas
        partes = linea.split("#", 1)[0].split()
        # Omitir lineas vacias y metricas ajenas a esta comparacion
        if not partes or partes[0] not in METRICAS:
            continue

        # Obtener el nombre exacto de la estadistica
        nombre = partes[0]
        # Rechazar las estadisticas que estam duplicadas o sin valor
        if nombre in valores or len(partes) < 2:
            # Informar del error
            raise ValueError(f"{ruta}: metrica duplicada o incompleta: {nombre}")


        # Convertir el valor sin perder precision decimal
        valor = Decimal(partes[1])
        # Rechazar los distintos numeros negativos, infinitos o de tipo NaN
        if not valor.is_finite() or valor < 0:
            # Detener la extraccion de datos invalidos y mostar el error correspondiente
            raise ValueError(f"{ruta}: valor invalido: {nombre}")


        # Distinguir la tasa de fallos de los contadores enteros
        if nombre.endswith("MissRate::total"):
            # Comprobar que la tasa no supere a 1
            if valor > 1:
                # Informar del error encontrado
                raise ValueError(f"{ruta}: tasa fuera de rango")
        # Exigir valores enteros para los demas contadores
        elif valor != valor.to_integral_value():
            # Informar del error
            raise ValueError(f"{ruta}: contador no entero: {nombre}")
        # Conservar la representacion decimal de la estadistica
        valores[nombre] = str(valor)


    # Identificar cualquier metrica ausente
    faltantes = set(METRICAS) - valores.keys()
    # Rechazar una corrida incompleta
    if faltantes:
        # Presentar el error
        raise ValueError(f"{ruta}: faltan {', '.join(sorted(faltantes))}")
    return valores



#---------------------------------------------------------------------------------------------
# Funcion Principal
# Generar el CSV solamente cuando ambas corridas sean validas
def main():

    # Capturar errores de archivos y de contenido
    try:
        # Leer las dos longitudes vectoriales antes de escribir
        datos = {vl: leer_memoria(vl) for vl in (512, 640)}
        # Preparar el archivo completo en memoria
        buffer = io.StringIO()
        # Configurar un escritor CSV con saltos de linea uniformes
        escritor = csv.writer(buffer, lineterminator="\n")
        # Identificar las dos configuraciones y el bloque utilizado
        escritor.writerow(("metrica", "N", "roi_block", "sve_vl512", "sve_vl640"))


        # Recorrer las metricas en el orden definido
        for nombre in METRICAS:
            # Escribir los valores originales de ambas corridas
            escritor.writerow((nombre, 128, 1, datos[512][nombre], datos[640][nombre]))
        # Crear la carpeta de resultados derivados si hace falta
        SALIDA.parent.mkdir(parents=True, exist_ok=True)
        # Guardar el CSV completo despues de validar ambas corridas
        SALIDA.write_text(buffer.getvalue(), encoding="utf-8")



    # Capturar tambien errores de conversion decimal
    except (OSError, ValueError, InvalidOperation) as error:
        # Mostrar el print en pantalla
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    # Confirmar las dos corridas, las ocho metricas y el bloque
    print("COMPARACION_MEMORIA_E3_OK CORRIDAS=2 METRICAS=8 BLOQUE_ROI=1")
    return 0

# Ejecutar el programa solamente al invocarlo directamente.
if __name__ == "__main__":
    sys.exit(main())
