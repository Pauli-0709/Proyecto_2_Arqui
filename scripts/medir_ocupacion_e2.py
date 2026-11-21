import csv  # Guardar una fila por cada uno de los ciclos
import re  # Buscar los numeros que aparecen en los mensajes del simulador
import shlex  # Recuperar los argumentos del comando oficial
import subprocess  # Ejecutar gem5 desde este script
import sys  # Permite leer N, ancho y ROB desde la terminal de linux
from pathlib import Path  # Construir rutas para los archivos
from tempfile import TemporaryDirectory  # Crear una carpeta aparte para esta prueba en especifico
from parse_stats import leer_roi  # Reutilizar el lector (ya realizado del repo) de la ROI

#============================================================================================================


if len(sys.argv) != 4:  # Se necesita tres valores despues de su nombre
    sys.exit("Uso: python3 scripts/medir_ocupacion_e2.py N ANCHO ROB")  # Mostrar en pantalla de como usarlo, si existe un error


n, ancho, rob = map(int, sys.argv[1:])  # Convertir los 3 valores a numeros
base = Path("results/e2")  # Carpeta que contiene los resultados
corrida = base / f"n{n}" / f"ancho{ancho}_rob{rob}"  # Buscar la configuracion solicitada
campos = ("simTicks", "finalTick", "simInsts", "system.cpu.numCycles")  # Datos que se van a comparar
oficial = leer_roi(corrida / "stats.txt", campos)  # Leer los datos de la corrida original



ciclos = oficial["system.cpu.numCycles"]  # Cantidad de ciclos que dura la ROI completa
periodo, resto = divmod(oficial["simTicks"], ciclos)  # Se calculan cuantos ticks dura un ciclo
if resto != 0 or periodo <= 0 or ciclos < 1024:  # Se comprueba que se pueda construir la ventana
    raise ValueError("Revisar el reloj o la longitud de la ROI")  # Detener la medicion si es invalida


inicio_roi = oficial["finalTick"] - oficial["simTicks"]  # Calcular el comienzo de la ROI
inicio = inicio_roi + ((ciclos - 1024) // 2) * periodo  # Se elige el comienzo de la ventana central
fin = inicio + 1024 * periodo  # Calcular en que tick se termina la ventana
esperados = range(inicio, fin, periodo)  # Se preparan los 1024 ticks que queremos encontrar


#=====================================================================================================


with TemporaryDirectory() as temporal:  # Guardar la simulacion nueva aparte de la oficial que ya se tiene
    carpeta = Path(temporal)  # Preparar la ruta temporal para la misma
    comando = shlex.split((corrida / "command.txt").read_text())  # Leer el comando original
    comando[comando.index("-d") + 1] = temporal  # Mandar los resultados a la carpeta temporal
    traza = carpeta / "ventana.log"  # Se elige donde guardar los mensajes de IQ y ROB


# "--debug-flags=IEW,Commit" -> se piden los mensajes de las 2 etapas que informan sobre las colas
# f"--debug-start={inicio}" -> activar los mensajes al comenzar la ventana
# f"--debug-end={fin}" -> desactivar los mensajes al terminar la ventana
# f"--debug-file={traza}" guardar la traza en un archivo por separado
    comando[1:1] = ["--debug-flags=IEW,Commit", f"--debug-start={inicio}", f"--debug-end={fin}", f"--debug-file={traza}"]


    prueba = subprocess.run(comando, capture_output=True, text=True)  # Ejecutar la simulacion respectiva
    registro = prueba.stdout + prueba.stderr  # Juntar los mensajes normales y los de error
    if prueba.returncode != 0 or f"N={n} CHECK=PASS errores=0" not in registro:
        raise RuntimeError(registro[-4000:])  # Mostrar el final del registro si falla el GEMM o el simualdor gem5


    repetida = leer_roi(carpeta / "stats.txt", campos)  # Leer los datos de la nueva corrida
    if repetida != oficial:  # Comparar ticks, instrucciones y ciclos con la corrida publicada
        raise ValueError("La ROI nueva difiere de la oficial")  # Evitar comparar corridas diferentes (error en pantalla)


    iq = {}  # Variable para guardar las entradas ocupadas de la IQ para cada tick
    rob_usado = {}  # Variable para guardar las entradas ocupadas del ROB para cada tick


    with traza.open() as archivo:  # Abrir el archivo de mensajes creado por el simulador

        for linea in archivo:  # Revisar los mensajes uno por uno
            tick, separador, mensaje = linea.partition(":")  # Separar el tick del resto del mensaje

            if not separador or not tick.strip().isdigit():  # Omitir las lineas sin tick numerico
                continue
            tick = int(tick)  # Convertir el tick a un numero

            if tick not in esperados:  # Revisar solo el intervalo seleccionado
                continue

            libres = re.search(r"IQ has (\d+) free entries", mensaje)  # Buscar entradas libres de la IQ
            ocupadas = re.search(r"ROB has (\d+) insts", mensaje)  # Buscar las diversas instrucciones dentro del ROB

            if libres:  # La IQ de estas corridas tiene una capacidad fija de 64 entradas
                iq[tick] = 64 - int(libres[1])  # Restar las libres para poder de esta manera calcular las ocupadas

            if ocupadas:  # El mensaje de ROB ya indica cuantas entradas estan ocupadas
                rob_usado[tick] = int(ocupadas[1])  # Se guarda ese valor para el mismo tick




if set(iq) != set(esperados) or set(rob_usado) != set(esperados):  # Exigir ambas medidas en cada ciclo
    raise ValueError(f"Ventana incompleta: IQ={len(iq)}, ROB={len(rob_usado)}")  # Mostrar que falto en la pantalla

for tick in esperados:  # Revisar que cada una de las mediciones quepa en la estructura correspondiente
    if not (0 <= iq[tick] <= 64 and 0 <= rob_usado[tick] <= rob):
        raise ValueError(f"Ocupacion imposible en tick {tick}")  # Identificar la muestra que fallo y ponerlo en pantalla



salida = base / "ocupacion" / f"n{n}_ancho{ancho}_rob{rob}.csv"  # Ruta de las muestras verificadas
salida.parent.mkdir(parents=True, exist_ok=True)  # Se crea la carpeta de ocupacion si hace falta
borrador = salida.with_suffix(".tmp")  # Escribir primero un archivo temporal para de esta manera evitar CSV a medias


with borrador.open("w", newline="") as archivo:  # Abrir el archivo temporal
    tabla = csv.writer(archivo)  # Preparar la escritura por filas
    tabla.writerow(("tick", "iq_ocupada", "rob_ocupado"))  # Escribir los nombres de las columnas
    for tick in esperados:  # Recorrer los ticks en orden
        tabla.writerow((tick, iq[tick], rob_usado[tick]))  # Se guardan las 2 medidas del mismo ciclo
borrador.replace(salida)  # Se genera el CSV cuando ya se escribieron todas las muestras


print(f"OCUPACION_OK N={n} ANCHO={ancho} ROB={rob} MUESTRAS={len(iq)}")  # Confirmar el resultado en pantalla
