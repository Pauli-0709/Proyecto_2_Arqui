#!/usr/bin/env python3
# La linea anterior permite ejecutar este archivo con Python 3.

# Bibliotecas
import csv  # Permite escribir las tablas de resultados
import math  # Permite comparar razones con tolerancia numerica
import sys  # Permite informar errores y devolver un codigo de salida
from decimal import Decimal  # Permite calcular tiempos y razones con precision decimal
from pathlib import Path  # Permite construir rutas de archivos
from parse_stats import extraer_fila  # Reutiliza el extractor de ROI ya validado

RAIZ = Path(__file__).resolve().parents[1]  # Ubica la raiz del repositorio
ENTRADA = RAIZ / "results/e3"  # Selecciona las simulaciones
SALIDA = ENTRADA / "summary"  # Separa las tablas de las carpetas de simulacion
TAMANOS = (64, 128)  # Define los tamanos establecidos en el enunciado
LONGITUDES = tuple(range(128, 1025, 128))  # Define las ocho longitudes vectoriales
PROGRAMAS = ("scalar", "sve")  # Define las versiones que se comparan

#---------------------------------------------------------------------------------------------------

# Funcion auxiliar guardar csv
# Esta funcion garantiza que la escritura de los archivos CSV sea robusta, evitando de esta manera corrupciones o archivos truncados si ocurre una
# interrupción repentina
def guardar_csv(ruta, filas):  # Escribe una tabla sin truncar primero el CSV anterior
    temporal = ruta.with_suffix(".csv.tmp")  # Define un temporal junto al destino
    with temporal.open("w", newline="", encoding="utf-8") as archivo:  # Abre el archivo temporal
        escritor = csv.DictWriter(archivo, fieldnames=list(filas[0]), lineterminator="\n")  # Define las columnas
        escritor.writeheader()  # Escribe los nombres de las columnas
        escritor.writerows(filas)  # Escribe todas las filas comprobadas
    temporal.replace(ruta)  # Reemplaza el CSV individual despues de cerrar su temporal

#---------------------------------------------------------------------------------------------------------------------------
# Funcion principal
def main():  # Coordina la extraccion, las comparaciones y la escritura
    try:  # Captura fallos de lectura y de validacion
        esperadas = set()  # Guarda las rutas exactas de las 32 corridas esperadas
        for n in TAMANOS:  # Recorre ambos tamanos de matriz
            for vl in LONGITUDES:  # Recorre las 8 longitudes vectoriales
                for programa in PROGRAMAS:  # Recorre escalar y SVE
                    esperadas.add(ENTRADA / f"n{n}/vl{vl}/{programa}/stats.txt")  # Construye la ruta

        encontradas = set(ENTRADA.rglob("stats.txt"))  # Busca las estadisticas disponibles
        if encontradas != esperadas:  # Rechaza corridas faltantes o adicionales
            faltantes = sorted(str(p.relative_to(RAIZ)) for p in esperadas - encontradas)  # Lista faltantes
            adicionales = sorted(str(p.relative_to(RAIZ)) for p in encontradas - esperadas)  # Lista adicionales
            raise ValueError(f"Faltantes: {faltantes}; adicionales: {adicionales}")  # Explica la diferencia

        corridas = []  # Acumula las 32 filas de metricas
        comparaciones = []  # Acumula las 16 parejas de resultados

		# Extraccion de metricas y validacion de integridad
        for n in TAMANOS:  # Agrupa los resultados por tamano de matriz
            for vl in LONGITUDES:  # Agrupa las parejas por longitud vectorial
                pareja = {}  # Conserva las dos versiones de esta configuracion

                for programa in PROGRAMAS:  # Procesa escalar y SVE por separado
                    ruta = ENTRADA / f"n{n}/vl{vl}/{programa}/stats.txt"  # Selecciona la corrida
                    validacion = (ruta.parent / "validation.txt").read_text(encoding="utf-8").strip()  # Lee su confirmacion
                    esperado = f"VALIDACION_E3_OK PROGRAMA={programa} N={n} VL_BITS={vl}"  # Define el contenido esperado
                    if validacion != esperado:  # Comprueba que la evidencia corresponde a esa configuracion
                        raise ValueError(f"Validacion incompatible: {ruta.parent}")  # Rechaza evidencia que sea equivocada
                    fila = extraer_fila(ruta)  # Extrae solamente las metricas del primer bloque
                    fila["ruta"] = ruta.relative_to(RAIZ).as_posix()  # Evita guardar las rutas personales absolutas
                    corridas.append({"N": n, "VL_BITS": vl, "programa": programa, **fila})  # Agrega parametros y metricas
                    pareja[programa] = fila  # Conserva la fila para calcular el speedup


				# Calculo de aceleracion (speedup) y reduccion de instrucciones
                escalar = pareja["scalar"]  # Obtiene la referencia escalar de la misma pareja
                sve = pareja["sve"]  # Obtiene la version vectorial correspondiente
                tiempo_escalar = Decimal(escalar["roi_seconds"])  # Recupera el tiempo escalar de la ROI
                tiempo_sve = Decimal(sve["roi_seconds"])  # Recupera el tiempo SVE de la ROI
                speedup_tiempo = tiempo_escalar / tiempo_sve  # Calcula la aceleracion usando tiempos simulados
                speedup_ciclos = Decimal(escalar["system.cpu.numCycles"]) / Decimal(sve["system.cpu.numCycles"])  # Calcula la razon de ciclos

                if not math.isclose(float(speedup_tiempo), float(speedup_ciclos), rel_tol=1e-6):  # Comprueba consistencia con igual frecuencia
                    raise ValueError(f"Revisar tiempos y frecuencias: N={n}, VL={vl}")  # Rechaza razones incompatibles

                reduccion = (Decimal(1) - Decimal(sve["simInsts"]) / Decimal(escalar["simInsts"])) * 100  # Calcula la reduccion porcentual de instrucciones
                comparaciones.append({  # Construye la fila de comparacion de esta pareja
                    "N": n,  # Identifica el tamano de matriz
                    "VL_BITS": vl,  # Identifica la longitud vectorial en bits
                    "instrucciones_scalar": escalar["simInsts"],  # Guarda las instrucciones escalares
                    "instrucciones_sve": sve["simInsts"],  # Guarda las instrucciones vectoriales
                    "ciclos_scalar": escalar["system.cpu.numCycles"],  # Guarda los ciclos escalares
                    "ciclos_sve": sve["system.cpu.numCycles"],  # Guarda los ciclos vectoriales
                    "segundos_scalar": str(tiempo_escalar),  # Guarda el tiempo simulado escalar
                    "segundos_sve": str(tiempo_sve),  # Guarda el tiempo simulado vectorial
                    "speedup_tiempo": format(speedup_tiempo, ".9f"),  # Guarda el speedup principal
                    "speedup_ciclos": format(speedup_ciclos, ".9f"),  # Guarda la comprobacion por ciclos
                    "reduccion_instrucciones_pct": format(reduccion, ".6f"),  # Guarda la reduccion porcentual
                })



		# Manejo de errores
        SALIDA.mkdir(parents=True, exist_ok=True)  # Crea la carpeta despues de comprobar todas las corridas
        guardar_csv(SALIDA / "e3_metricas.csv", corridas)  # Guarda las metricas de las 32 corridas
        guardar_csv(SALIDA / "e3_speedup.csv", comparaciones)  # Guarda las 16 comparaciones

    except (OSError, ValueError) as error:  # Captura errores de archivos o comprobaciones
        print(f"ERROR: {error}", file=sys.stderr)  # Muestra el motivo sin anunciar exito
        return 1

    print(f"RESUMEN_E3_OK CORRIDAS={len(corridas)} PAREJAS={len(comparaciones)}")  # Confirma el procesamiento completo
    return 0


if __name__ == "__main__":  # Ejecuta main solamente al llamar directamente al script
    sys.exit(main())  # Devuelve al sistema el resultado del procesamiento
