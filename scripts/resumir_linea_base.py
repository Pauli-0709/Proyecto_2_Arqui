#!/usr/bin/env python3

#-------------------------------------------------
# Permite leer carpetas y archivos.
from pathlib import Path

# Permite leer la configuracion que guardo el simulador gem5.
from configparser import ConfigParser

# Permite escribir las filas del archivo CSV.
import csv

# Permite recibir las rutas desde la terminal de Ubuntu.
import sys

# Permite distinguir los nombres de los nucleos.
import re

# Reutiliza el lector que esta en el repositorio y que el mismo valida el primer bloque de la ROI.
from parse_stats import leer_roi

# Reutiliza el lector de contadores de cache del mismo bloque.
from stats_gem5 import primer_bloque


#---------------------------------------------------------------------
# Relaciona la carpeta, el modelo y su tipo en el archivo config.ini.
MODELOS = (
    ("temporizado", "ArmTimingSimpleCPU", "BaseTimingSimpleCPU"),
    ("minor", "ArmMinorCPU", "BaseMinorCPU"),
    ("fuera_de_orden", "ArmO3CPU", "BaseO3CPU"),
)

#-----------------------------------------------------
# Funcion para calcular los fallos y el porcentaje de una cache.
def medir_cache(datos, prefijo):

    # Arma los nombres de los contadores de esta cache.
    claves = [f"{prefijo}.overall{nombre}::total" for nombre in ("Hits", "Misses", "Accesses")]
    # El simulador gem5 omite los contadores que valen 0.
    aciertos, fallos, accesos = (datos.get(clave, 0) for clave in claves)

    # Comprueba que el total coincida con aciertos mas fallos.
    if any(valor < 0 or int(valor) != valor for valor in (aciertos, fallos, accesos)) or aciertos + fallos != accesos:
        # Detiene la extraccion si los contadores no coinciden y genera el error.
        raise ValueError(f"Contadores incoherentes en {prefijo}")
    # Deja el porcentaje vacio si la cache no recibio accesos.
    tasa = 100 * fallos / accesos if accesos else ""

    # Devuelve los fallos, los accesos y el porcentaje.
    return int(fallos), int(accesos), tasa



#-------------------------------------------------------------------
# Funcion que lee una corrida y prepara su fila respectiva.
def extraer(carpeta, n, modelo, tipo):

    # Comprueba que el resultado obtenido del GEMM sea correcto para este tamano en especifico.
    if not any(linea.startswith(f"N={n} CHECK=PASS errores=0 ") for linea in (carpeta / "run.log").read_text().splitlines()):
        # Rechaza una corrida que no tenga la comprobacion esperada y genera el error.
        raise ValueError(f"{carpeta}: falta la comprobacion de GEMM")
    # Prepara la lectura de la configuracion.
    configuracion = ConfigParser(interpolation=None)

    # Abre el archivo que se genero en  el simulador gem5.
    with (carpeta / "config.ini").open() as archivo:
        configuracion.read_file(archivo)
    # Encuentra los nucleos que aparecen en el sistema.
    nucleos = [nombre for nombre in configuracion["system"]["children"].split() if re.fullmatch(r"cpu[0-9]*", nombre)]

    # Comprueba que se uso un solo nucleo del modelo de ARM solicitado en la prueba.
    if nucleos != ["cpu"] or configuracion["system.cpu"]["type"] != tipo or configuracion["system.cpu.isa"]["type"] != "ArmISA":
        # Detiene la extraccion si la CPU no coincide y genera el error correspondiente.
        raise ValueError(f"{carpeta}: configuracion de CPU inesperada")


    # Ubica el reloj que usa el nucleo.
    dominio = configuracion["system.cpu"]["clk_domain"]

    # Lee cuantos ticks dura cada ciclo en especifico.
    periodo = int(configuracion[dominio]["clock"])

    # Localiza el archivo de las estadisticas correspondientes.
    ruta = carpeta / "stats.txt"

    # Lee las instrucciones y la duracion del primer bloque.
    roi = leer_roi(ruta)

    # Verifica que el reloj de la CPU sea de un frecuencia de 2 GHz.
    if roi["simFreq"] != 2_000_000_000 * periodo:
        # Detiene la extraccion si el reloj no coincide y genera el error.
        raise ValueError(f"{carpeta}: el nucleo debe funcionar a 2 GHz")

    # Convierte la duracion de la ROI de ticks a ciclos y la guarda.
    ciclos = roi["simTicks"] / periodo

    # Lee las estadisticas del primer bloque las cuales corresponde a la ROI.
    datos = primer_bloque(ruta)

    # Guarda el total de instrucciones retiradas por el nucleo.
    instrucciones = int(datos["system.cpu.commitStats0.numInsts"])

    # Lee el IPC y el CPI que el simulador gem5 reporta para el nucleo.
    ipc = datos["system.cpu.ipc"]
    cpi = datos["system.cpu.cpi"]

    # Comprueba la presencia de ambas caches.
    for cache in ("system.cpu.dcache", "system.l2"):

        # Busca cada cache en la configuracion y en las estadisticas correspondientes.
        if cache not in configuracion or not any(clave.startswith(cache + ".") for clave in datos):
            # Detiene la extraccion si falta evidencia de una cache y genera su error.
            raise ValueError(f"{carpeta}: no hay evidencia de {cache}")


    # Extrae los fallos, los accesos y el porcentaje de la cache L1 de datos.
    fallos_l1d, accesos_l1d, tasa_l1d = medir_cache(datos, "system.cpu.dcache")

    # Verificacion para saber si la multiplicacion debe haber usado la cache de datos.
    if not accesos_l1d:
        # Rechaza corridas sin accesos a L1D y genera el error.
        raise ValueError(f"{carpeta}: no hay accesos a L1D")

    # Extrae los fallos, los accesos y el porcentaje local de la cache L2.
    fallos_l2, accesos_l2, tasa_l2 = medir_cache(datos, "system.l2")

    # Devuelve la fila con sus ciclos, el IPC, el CPI y los datos de las 2 caches.
    return {
        "n": n, "cpu": modelo, "ciclos": ciclos, "ciclos_cpu": roi["system.cpu.numCycles"],
		"instrucciones": instrucciones, "ipc": ipc, "cpi": cpi,
        "fallos_l1d": fallos_l1d, "accesos_l1d": accesos_l1d, "tasa_l1d_pct": tasa_l1d,
        "fallos_l2": fallos_l2, "accesos_l2": accesos_l2, "tasa_l2_pct": tasa_l2,
        "ticks_roi": roi["simTicks"], "periodo_ticks": periodo,
    }


# Pide la carpeta de las 6 corridas y la ruta de salida para al prueba.
if len(sys.argv) != 3:

    # Muestra el uso si faltan argumentos y genera el error.
    sys.exit("Uso: resumir_linea_base.py carpeta_corridas archivo.csv")

# Separa la carpeta de entrada de la ruta del archivo CSV.
entrada, salida = map(Path, sys.argv[1:])


# Reune las 6 filas correspondientes antes de crear el archivo CSV.
filas = [
    extraer(entrada / f"n{n}" / nombre, n, modelo, tipo)
    for n in (64, 128)
    for nombre, modelo, tipo in MODELOS
]



# Abre el archivo CSV despues de validar las 6 corridas correspondientes.
with salida.open("w", newline="", encoding="utf-8") as archivo:

	# Usa el salto de linea de Linux al escribir el archivo CSV.
    escritor = csv.DictWriter(archivo, fieldnames=list(filas[0]), lineterminator="\n")
    # Escribe los encabezados.
    escritor.writeheader()
    # Escribe una fila por cada una de las combinaciones.
    escritor.writerows(filas)


# Muestra cuantas corridas se guardaron en pantalla.
print(f"Se guardaron {len(filas)} corridas en {salida}")
