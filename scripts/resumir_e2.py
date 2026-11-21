import csv  # Permite guardar los resultados obtenidos en la tabla CSV
from itertools import product  # Combina cada tamano con cada ancho y cada ROB obtenido
from pathlib import Path  # Permite trabajar con carpetas y archivos
from parse_stats import INICIO, FIN, extraer_fila  # Llamada para reutilizar el lector del proyecto

#==================================================================================================


base = Path("results/e2")  # Carpeta que contiene las corridas oficiales del experimento E2
filas = []  # Aqui se va a guardar una fila por cada corrida


# "ipc": "system.cpu.ipc" -> instruccion que van hacer ejecutadas por ciclo
# "iq_llena_iew": "system.cpu.iew.iqFullEvents" -> bloques por la IQ llena
# "rob_lleno_rename": "system.cpu.rename.ROBFullEvents" -> bloques por el ROB lleno
# "fallos_prediccion": "system.cpu.branchPred.mispredicted_0::total" -> saltos que pueden estar mal predichos
# "fallos_l1d": "system.cpu.dcache.overallMisses::total" -> fallos en la cache L1 de datos
# "fallos_l2": "system.l2.overallMisses::total" -> fallos en la cache L2

contadores = {"ipc": "system.cpu.ipc", "iq_llena_iew": "system.cpu.iew.iqFullEvents", "rob_lleno_rename": "system.cpu.rename.ROBFullEvents", "fallos_prediccion": "system.cpu.branchPred.mispredicted_0::total", "fallos_l1d": "system.cpu.dcache.overallMisses::total", "fallos_l2": "system.l2.overallMisses::total"}

#=============================================================================================================


# Recorrer los 2 tamanos objetivos (64 y 128), los 4 anchos (1, 2, 4 y 8) y los 3 tamanos del ROB que se necesitan (32, 64 y 192)
for n, ancho, rob in product((64, 128), (1, 2, 4, 8), (32, 64, 192)):
    carpeta = base / f"n{n}" / f"ancho{ancho}_rob{rob}"  # Ruta de esta corrida
    ruta = carpeta / "stats.txt"  # Se elige el archivo de estadisticas
    basicas = extraer_fila(ruta)  # Comprobar la corrida y leer sus datos basicos

    texto = ruta.read_text()  # Leer el contenido del archivo especifico
    desde_inicio = texto.split(INICIO, 1)[1]  # Se inicia con en el primer bloque de estadisticas
    bloque = desde_inicio.split(FIN, 1)[0]  # Terminar al final de ese primer bloque
    valores = {}  # Esta variable guarda los nombres y valores que aparecen en ese bloque

    for linea in bloque.splitlines():  # Leer las estadisticas una linea por ciclo
        datos = linea.split("#", 1)[0].split()  # Eliminar el comentario del simulador gem5 y poder separar los datos
        if len(datos) >= 2:  # Usar las lineas que tienen un nombre y un valor
            valores[datos[0]] = datos[1]  # Se guarda el valor bajo el nombre de la estadistica



# N -> tamano de la matriz
# ancho -> ancho que es la configuracion para el nucleo
# ROB -> cantidad de entradas disponibles en el ROB
# instrucciones: basicas [simInsts] -> instrucciones ejecutadas dentro de la ROI
# ciclos: basicas[system.cpu.numCycles] -> ciclos de duracion de la ROI
# segundos_roi: basicas [roi_seconds] -> tiempo siomulado de duracion de la ROI

    fila = {"N": n, "ancho": ancho, "ROB": rob, "instrucciones": basicas["simInsts"], "ciclos": basicas["system.cpu.numCycles"], "segundos_roi": basicas["roi_seconds"]}

    for columna, nombre in contadores.items():  # Agregar cada una de las metricas de E2 a la fila correspodiente
        if columna == "rob_lleno_rename" and nombre not in valores:
            fila[columna] = "no_impreso"
        else:
            fila[columna] = valores[nombre]  # Copiar el valor que se imprimio en el simulador gem5

    filas.append(fila)  # Guardar la fila terminada antes de pasar a la siguiente corrida




salida = base / "summary" / "e2_metricas.csv"  # Elegir el nombre del CSV
salida.parent.mkdir(parents=True, exist_ok=True)  # Crear la carpeta summary si hace falta


with salida.open("w", newline="") as archivo:  # Abrir el archivo para poder escribir la tabla
    tabla = csv.DictWriter(archivo, fieldnames=filas[0].keys())  # Usar las claves como columnas
    tabla.writeheader()  # Escribir una vez los nombres de las columnas
    tabla.writerows(filas)  # Escribir las 24 filas de resultados correspondientes

print(f"E2_CSV_OK CORRIDAS={len(filas)} ARCHIVO={salida}")  # Mostrar donde quedo el archivo CSV
