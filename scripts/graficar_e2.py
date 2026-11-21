import csv  # Libreria para leer y escribir las tablas del experimento
from itertools import product  # Recorrer las 24 configuraciones
from pathlib import Path  # Trabajar con las rutas de cada archivo
from statistics import mean  # Esta permite calcularr el promedio de las 1024 muestras ejecutadas en el experimento
import matplotlib  # Herramienta para generar los graficos
matplotlib.use("Agg")  # Heramienta para guardar las imagenes dentro del Docker sin abrir ventanas
import matplotlib.pyplot as plt  # Permite dibujar las curvas y colocar los nombres de los ejes

#=========================================================================================================


base = Path("results/e2")  # Carpeta del experimento
figuras = base / "figures"  # Carpeta donde quedaran las imagenes
figuras.mkdir(parents=True, exist_ok=True)  # Crear la carpeta si todavia esta no existe
anchos = (1, 2, 4, 8)  # Valores que iran en el eje horizontal
robs = (32, 64, 192)  # Cada tamano de ROB tendra su propia curva



with (base / "summary/e2_metricas.csv").open() as archivo:  # Abrir el archivo CSV
    metricas = list(csv.DictReader(archivo))  # Leer cada corrida usando sus nombres de columna

ipc = {}  # Variable para guardar el IPC bajo la combinacion de N, ancho y ROB

# For para revisar cada fila del archivo CSV
for fila in metricas:
    clave = (int(fila["N"]), int(fila["ancho"]), int(fila["ROB"]))  # Identificar la corrida
    ipc[clave] = float(fila["ipc"])  # Guardar el IPC como un numero

figura, paneles = plt.subplots(1, 2, figsize=(10, 4), sharey=True)  # Un panel por tamano de matriz


# Este for va a dibujar primero para el tamano de n=64 y lyego para un n=128
for panel, n in zip(paneles, (64, 128)):

	# For para dibujar un curva por cada tamano del ROB
    for rob in robs:
        puntos = [ipc[n, ancho, rob] for ancho in anchos]  # Ordenar los IPC segun el ancho
        panel.plot(anchos, puntos, marker="o", label=f"ROB {rob}")  # Se dibuja la curva
    panel.set(title=f"N = {n}", xlabel="Ancho del nucleo", xticks=anchos)  # Nombrar el panel y el eje correspondiente
    panel.grid(alpha=0.3)  # Agregar una cuadricula

paneles[0].set_ylabel("IPC (instrucciones por ciclo)")  # Leyenda del eje
paneles[1].legend()  # Mostrar a que ROB corresponde cada curva
figura.tight_layout()  # Acomodar los titulos y ejes de forma correcta
figura.savefig(figuras / "e2_ipc.png", dpi=180)  # Guardar el primer grafico realizado
plt.close(figura)  # Cerrar el grafico antes de hacer el siguiente


resumen = []  # Guardar una fila de ocupacion media por cada una de las configuraciones



# Este for revisa las 24 configuraciones
for n, ancho, rob in product((64, 128), anchos, robs):
    ruta = base / "ocupacion" / f"n{n}_ancho{ancho}_rob{rob}.csv"  # Se buscan las muestras

    with ruta.open() as archivo:  # Abrir el archivo correspondiente
        muestras = list(csv.DictReader(archivo))  # Leer las muestras como filas con nombre

    ticks = {int(m["tick"]) for m in muestras}  # Contar cada uno de los instantes diferentes que se midieron

    if len(muestras) != 1024 or len(ticks) != 1024:  # Detectar muestras faltantes o repetidas en la ejecucion
        raise ValueError(f"Revisar las 1024 muestras de {ruta}")  # Mostrar el archivo que se debe revisar, en pantalla

    iq_media = mean(int(m["iq_ocupada"]) for m in muestras)  # Promedio de entradas ocupadas en IQ
    rob_media = mean(int(m["rob_ocupado"]) for m in muestras)  # Promedio de entradas ocupadas en ROB


#==========================================================================
# n -> tamano de la matriz
# ancho -> ancho del nucleo
# ROB -> tamano del ROB
# iq_media_entradas: iq_media -> promedio de entradas de IQ ocupadas
# "rob_media_entradas": rob_media  -> promedio de entradas de ROB ocupadas
# "iq_porcentaje": 100 * iq_media / 64 -> porcentaje de las 64 configuraciones de IQ
# "rob_porcentaje": 100 * rob_media / rob -> porcentaje de la capacidad del ROB

# Esto guardara los datos de la configuracion
    resumen.append({"N": n, "ancho": ancho, "ROB": rob, "muestras": len(muestras), "iq_media_entradas": iq_media, "rob_media_entradas": rob_media, "iq_porcentaje": 100 * iq_media / 64, "rob_porcentaje": 100 * rob_media / rob})

#==============================================================================================


with (base / "summary/e2_ocupacion.csv").open("w", newline="") as archivo:  # Abrir el segundo archivo CSV
    tabla = csv.DictWriter(archivo, fieldnames=resumen[0].keys())  # Usar los nombres del resumen
    tabla.writeheader()  # Escribir el encabezado
    tabla.writerows(resumen)  # Escribir las 24 configuraciones


figura, paneles = plt.subplots(2, 2, figsize=(10, 7), sharex=True, sharey=True)  # Crear cuatro paneles
medidas = (("iq_porcentaje", "IQ"), ("rob_porcentaje", "ROB"))  # Elegir que mostrar en cada una de las filas

# For para usar una columna por tamano de matriz
for columna, n in enumerate((64, 128)):

# For para usar una fila para IQ y la otra para el ROB
    for fila, (campo, nombre) in enumerate(medidas):
        panel = paneles[fila, columna]  # Seleccionar donde se dibujara la curva

# For para dibujar una curva para cada uno de los ROB
        for rob in robs:
            datos = [d for d in resumen if d["N"] == n and d["ROB"] == rob]  # Elegir los 4 anchos
            porcentajes = [d[campo] for d in datos]  # Leer los porcentajes de esa curva
            panel.plot(anchos, porcentajes, marker="o", label=f"ROB {rob}")  # Dibujar los 4 puntos
        panel.set(title=f"{nombre}, N = {n}", xticks=anchos, ylim=(0, 100))  # Se utilizo una escala de 0 a 100
        panel.grid(alpha=0.3)  # Agregar la cuadricula


        if fila == 1:  # El nombre del eje horizontal se muestra debajo
            panel.set_xlabel("Ancho del nucleo")  # Label del grafico
        if columna == 0:  # El nombre del eje vertical se muestra a la izquierda
            panel.set_ylabel("Ocupacion media (%)")  # Indicar la unidad del eje



paneles[0, 1].legend()  # Identificar los 3 tamanos del ROB
figura.suptitle("Ocupacion en los 1024 ciclos centrales de la ROI")  # Indicar que se uso una ventana
figura.tight_layout()  # Acomodar el layout
figura.savefig(figuras / "e2_ocupacion.png", dpi=180)  # Guardar el segundo grafico
plt.close(figura)  # Cerrar la figura al terminar


print("E2_GRAFICOS_OK")  # Confirmar que se terminaron ambos graficos, en pantalla
