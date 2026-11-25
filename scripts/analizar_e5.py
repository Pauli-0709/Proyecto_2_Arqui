# Extrae las metricas del experimento E5 y genera los archivos CSV, las figuras y el resumen correspondiente.

import csv
import sys
from math import isfinite, log10
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # Dibuja los graficos sin abrir una ventana.
import matplotlib.pyplot as plt
from matplotlib.ticker import (
    FuncFormatter, LogLocator, MaxNLocator, ScalarFormatter, SymmetricalLogLocator,
)

from parse_stats import METRICAS_GLOBALES, extraer_fila
from stats_gem5 import primer_bloque

HILOS = range(2, 9)  # Usa las mismas configuraciones que el barrido.
MODOS = ("con_relleno", "sin_relleno")
TAMANOS = (64, 128)
EVENTOS = {
    "MESI": ("S.Inv", "M.Fwd_GETX"),
    "MOESI": ("S.Inv", "O.Fwd_GETX", "MM.Fwd_GETX", "MM.Fwd_GETS"),
}
L1 = "system.ruby.L1Cache_Controller."
RED = "system.ruby.network.msg_count."
LATENCIA = "system.ruby.m_missLatencyHistSeqr"

#----------------------------------------------------------------------------

def leer(raiz, programa, nombre, protocolo, hilos, n="", modo=""):

    # Localiza una corrida de esta ejecucion y comprueba su validacion.
    carpeta = raiz / programa / nombre
    validacion = (carpeta / "validation.txt").read_text(encoding="utf-8")
    if not validacion.startswith("estado=PASS\n"):
        raise ValueError(f"Corrida sin validar: {carpeta}")

    # Obtiene los ticks y las instrucciones del primer bloque completo.
    ruta = carpeta / "stats.txt"
    globales = extraer_fila(ruta, solo_globales=True)
    globales["ruta"] = ruta.relative_to(raiz).as_posix()

    # Extrae los contadores de Ruby de esa misma region de interes.
    stats = primer_bloque(ruta)
    mensajes = [v for k, v in stats.items() if k.startswith(RED)]
    if not mensajes:
        raise ValueError(f"Faltan contadores de red Ruby: {ruta}")

    # EL simulador gem5 puede omitir el contador de una transicion que ocurrio 0 veces.
    invalidaciones = sum(stats.get(f"{L1}{evento}::total", 0) for evento in EVENTOS[protocolo])
    coherencia = dict(
        programa=programa, protocolo=protocolo, n=n, hilos=hilos, modo=modo,
        roi_seconds=globales["roi_seconds"], invalidaciones_estables=int(invalidaciones),
        trafico_red_suma_msg_count=int(sum(mensajes)),
        muestras_fallos_ruby=int(stats[f"{LATENCIA}::samples"]),
        latencia_media_ciclos_secuenciador=stats[f"{LATENCIA}::mean"],
        ruta=globales["ruta"],
    )
    return globales, coherencia


#-----------------------------------------------------------

def escribir_csv(ruta, filas, columnas):

    # Guarda una fila por corrida respetando el orden de las diversas columnas.
    with ruta.open("w", encoding="utf-8", newline="") as archivo:
        tabla = csv.DictWriter(archivo, fieldnames=columnas)
        tabla.writeheader()
        tabla.writerows(filas)

#----------------------------------------------------------------------

def ajustar_eje_y(eje, etiqueta, es_conteo):

    # Toma los valores validos de todas las curvas de este panel.
    valores = [
        valor
        for curva in eje.get_lines()
        for valor in curva.get_ydata()
        if isfinite(valor)
    ]
    eje.set_ylabel(etiqueta)
    if not valores:
        return

    minimo, maximo = min(valores), max(valores)
    if minimo > 0 and maximo >= 100 * minimo:

        # Usar la escala logaritmica si los valores abarcan 2 decadas o mas.
        margen = 0.07 * (log10(maximo) - log10(minimo))
        eje.set_yscale("log")
        eje.set_ylim(minimo / 10**margen, maximo * 10**margen)
        eje.yaxis.set_major_locator(LogLocator(base=10))
        eje.set_ylabel(f"{etiqueta}\nEscala logaritmica")
    elif minimo == 0 and maximo >= 100:

        # Conserva el 0 cuando tambien hay valores de varios tamanos.
        eje.set_yscale("symlog", linthresh=1)
        eje.set_ylim(0, 1.25 * maximo)
        eje.yaxis.set_major_locator(SymmetricalLogLocator(base=10, linthresh=1))
        eje.set_ylabel(f"{etiqueta}\nEscala semilogaritmica con cero")
    else:

        # Acerca el eje a los datos y deja espacio alrededor de los puntos.
        margen = 0.10 * (maximo - minimo or abs(maximo) or 1)
        if es_conteo:
            margen = max(margen, 1)
        inferior = max(0, minimo - margen) if minimo >= 0 else minimo - margen
        eje.set_ylim(inferior, maximo + margen)
        eje.yaxis.set_major_locator(
            MaxNLocator(nbins=6, integer=es_conteo, min_n_ticks=2)
        )
        if es_conteo:

            # Mostrar conteos enteros.
            eje.yaxis.set_major_formatter(
                FuncFormatter(lambda valor, _: f"{valor:,.0f}".replace(",", " "))
            )
        else:
            formato = ScalarFormatter(useOffset=False)
            formato.set_scientific(False)
            eje.yaxis.set_major_formatter(formato)

#--------------------------------------------------------------------------

def graficar(carpeta, falso, gemm):

    # Define el nombre, los datos y la unidad de cada figura.
    medidas = (
        ("tiempos", "roi_seconds", "Tiempo de la ROI (ms)", 1000, False),
        ("invalidaciones", "invalidaciones_estables", "Invalidaciones estables (eventos)", 1, True),
        ("trafico", "trafico_red_suma_msg_count", "Trafico de red (mensajes)", 1, True),
        ("latencia", "latencia_media_ciclos_secuenciador",
         "Latencia media de fallo (ciclos Ruby)", 1, False),
    )
    colores = {"MESI": "#2563a6", "MOESI": "#ad460f"}
    titulos = ("Falso compartido", "GEMM N=64", "GEMM N=128")

    for nombre, columna, etiqueta, factor, es_conteo in medidas:
        figura, ejes = plt.subplots(
            1, 3, figsize=(15, 4.7), constrained_layout=True
        )
        for protocolo, color in colores.items():
            for modo in MODOS:
                valores = [
                    float(falso[protocolo, h, modo][columna]) * factor for h in HILOS
                ]

                # Usa el mismo color por protocolo y distingue los modos con el trazo.
                estilo = "o--" if modo == "con_relleno" else "s-"
                ejes[0].plot(
                    HILOS, valores, estilo, color=color, markersize=5,
                    label=f"{protocolo} {modo.replace('_', ' ')}",
                )
            for eje, n in zip(ejes[1:], TAMANOS):
                valores = [float(gemm[protocolo, h, n][columna]) * factor for h in HILOS]
                eje.plot(HILOS, valores, "o-", color=color, markersize=5, label=protocolo)

        for eje, titulo in zip(ejes, titulos):

            # Ajusta la escala de cada panel y muestra sus valores y su cuadricula respectiva.
            eje.set(title=titulo, xlabel="Nucleos / hilos", xticks=list(HILOS))
            ajustar_eje_y(eje, etiqueta, es_conteo)
            eje.tick_params(axis="y", labelleft=True)
            eje.set_axisbelow(True)
            eje.grid(True, which="major", axis="both", color="0.85", linewidth=0.7)

            # Colocar la leyenda debajo del panel para dejar libres las curvas.
            eje.legend(loc="upper center", bbox_to_anchor=(0.5, -0.18), ncol=2, fontsize=9)

        figura.savefig(carpeta / f"e5_{nombre}.png", dpi=160)
        plt.close(figura)

#-------------------------------------------------------
def resumir(ruta, falso, gemm):

    # Calcula tiempos en ms y los cocientes con datos de la misma configuracion.
    lineas = [
        "# E5. Resumen del barrido", "",
        "## Falso compartido", "",
        "Cada cociente divide el tiempo sin relleno entre el tiempo con relleno.", "",
        "| Nucleos | Penalizacion MESI (x) | Penalizacion MOESI (x) |",
        "| ---: | ---: | ---: |",
    ]


    for h in HILOS:
        razones = []
        for p in EVENTOS:
            con = float(falso[p, h, "con_relleno"]["roi_seconds"])
            sin = float(falso[p, h, "sin_relleno"]["roi_seconds"])
            razones.append(sin / con)
        lineas.append(f"| {h} | {razones[0]:.3f} | {razones[1]:.3f} |")

    lineas += [
        "", "## GEMM paralelo", "",
        "| N | Nucleos | MESI (ms) | MOESI (ms) | MOESI / MESI |",
        "| ---: | ---: | ---: | ---: |",
    ]


    for n in TAMANOS:
        for h in HILOS:
            mesi = 1000 * float(gemm["MESI", h, n]["roi_seconds"])
            moesi = 1000 * float(gemm["MOESI", h, n]["roi_seconds"])
            lineas.append(f"| {n} | {h} | {mesi:.6f} | {moesi:.6f} | {moesi / mesi:.3f} |")

    # Incluye las metricas de Ruby de las comparaciones de mayor numero de nucleos.
    lineas += [
        "", "## Coherencia con 8 nucleos", "",
        "| Caso | Protocolo | Invalidaciones | Mensajes | Muestras | Latencia (ciclos Ruby) |",
        "| --- | --- | ---: | ---: | ---: | ---: |",
    ]
    for nombre, grupo, casos in (("Falso", falso, MODOS), ("GEMM", gemm, TAMANOS)):
        for caso in casos:
            for protocolo in EVENTOS:
                fila = grupo[protocolo, 8, caso]
                lineas.append(
                    f"| {nombre} {caso} | {protocolo} | {fila['invalidaciones_estables']} | "
                    f"{fila['trafico_red_suma_msg_count']} | {fila['muestras_fallos_ruby']} | "
                    f"{fila['latencia_media_ciclos_secuenciador']:.3f} |"
                )
    ruta.write_text("\n".join(lineas) + "\n", encoding="utf-8")

#----------------------------------------------------------------------------------

def main(raiz):

    # Recorre la matriz completa y se detiene si falta una corrida a ejecutar.
    gp_falso, gp_gemm, falso, gemm = [], [], {}, {}

    for protocolo in EVENTOS:
        for h in HILOS:
            for modo in MODOS:
                g, fila = leer(raiz, "falso_compartido", f"{protocolo}_h{h}_{modo}", protocolo, h, modo=modo)
                gp_falso.append(g)
                falso[protocolo, h, modo] = fila
            for n in TAMANOS:
                g, fila = leer(raiz, "gemm", f"{protocolo}_n{n}_h{h}", protocolo, h, n=n)
                gp_gemm.append(g)
                gemm[protocolo, h, n] = fila



    # Escribe las salidas despues de comprobar los 56 casos requeridos.
    tablas, figuras = raiz / "summary", raiz / "figures"
    tablas.mkdir(exist_ok=True)
    figuras.mkdir(exist_ok=True)
    columnas = ["ruta", "roi_block", *METRICAS_GLOBALES, "roi_seconds"]
    escribir_csv(tablas / "falso_compartido_roi.csv", gp_falso, columnas)
    escribir_csv(tablas / "gemm_roi.csv", gp_gemm, columnas)
    filas = [*falso.values(), *gemm.values()]
    escribir_csv(tablas / "e5_coherencia.csv", filas, list(filas[0]))
    graficar(figuras, falso, gemm)
    resumir(tablas / "e5_resumen.md", falso, gemm)
    print(f"ANALISIS_E5_OK CORRIDAS={len(filas)} CSV=3 FIGURAS=4")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Uso: python3 scripts/analizar_e5.py CARPETA_DE_CORRIDAS")
    try:
        main(Path(sys.argv[1]))
    except (OSError, ValueError, KeyError) as error:
        raise SystemExit(f"ERROR E5: {error}") from None
