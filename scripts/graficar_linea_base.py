#!/usr/bin/env python3

#---------------------------------------------------
# Permite leer el archivo CSV.
import csv

# Permite recibir las rutas desde la terminal en Linux.
import sys

# Carga la herramienta de graficos que se va a utilizar.
import matplotlib

# Genera la imagen.
matplotlib.use("Agg")

# Carga los distintos comandos para poder dibujar.
import matplotlib.pyplot as plt
#--------------------------------------------------------


# Pide la ruta del archivo CSV y la ruta de la imagen correspondiente.
if len(sys.argv) != 3:
    # Muestra el uso si faltan argumentos y genera el error.
    sys.exit("Uso: graficar_linea_base.py resumen.csv grafico.png")

# Abre el archivo CSV generado por el resumen.
with open(sys.argv[1], newline="", encoding="utf-8") as archivo:
    # Ubica cada fila por tamano y modelo correspondiente.
    datos = {(int(fila["n"]), fila["cpu"]): fila for fila in csv.DictReader(archivo)}


# Define el orden de los modelos.
modelos = ("ArmTimingSimpleCPU", "ArmMinorCPU", "ArmO3CPU")
# Usa etiquetas cortas para el eje horizontal.
etiquetas = ("TimingSimple", "Minor", "O3")
# Coloca los dos graficos en una imagen.
figura, ejes = plt.subplots(1, 2, figsize=(10, 4), constrained_layout=True)
# Define las medidas y sus unidades.
medidas = (("ipc", "Instrucciones por ciclo"), ("ciclos", "Ciclos de la ROI"))




# Dibuja el IPC a la izquierda y los ciclos a la derecha.
for eje, (columna, unidad) in zip(ejes, medidas):

    for n, ajuste in ((64, -0.18), (128, 0.18)):
        valores = [float(datos[n, modelo][columna]) for modelo in modelos]
        eje.bar([i + ajuste for i in range(len(modelos))], valores, 0.34, label=f"N={n}")

    eje.set_xticks(range(len(modelos)), etiquetas)
    eje.set_ylabel(unidad)
    eje.legend()

# Titulo
figura.suptitle("E1 - GEMM escalar con un nucleo")
# Guarda la imagen para el informe y la presentacion posterior.
figura.savefig(sys.argv[2], dpi=180)



# Calcula la ganancia de O3 para cada tamano que se efectuo la prueba.
for n in (64, 128):
    # Lee los ciclos transcurridos con el modelo de O3.
    ciclos_o3 = float(datos[n, "ArmO3CPU"]["ciclos"])

    # Compara el modelo de O3 con cada modelo en orden.
    for base in modelos[:2]:
        # Lee los diversos ciclos del modelo de referencia.
        ciclos_base = float(datos[n, base]["ciclos"])
        # Muestra la aceleracion y el cambio porcentual de los ciclos.
        print(f"N={n} O3 frente a {base}: {ciclos_base / ciclos_o3:.3f}x; reduccion de ciclos {(1 - ciclos_o3 / ciclos_base) * 100:.2f}%")
