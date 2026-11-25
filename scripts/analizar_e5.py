# Extrae las metricas del experimento E5 y genera los archivos CSV, las figuras y el resumen correspondiente.

import csv
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # Dibuja los graficos sin abrir una ventana.
import matplotlib.pyplot as plt

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

def graficar(carpeta, falso, gemm):

    # Dibuja 3 ventanas para grafico por cada metrica: falso compartido, GEMM con tamano de N=64 y GEMM con tamano de N=128.
    medidas = (
        ("tiempos", "roi_seconds", "Tiempo de la ROI (ms)", 1000),
        ("invalidaciones", "invalidaciones_estables", "Invalidaciones estables", 1),
        ("trafico", "trafico_red_suma_msg_count", "Mensajes de red sumados por tipo", 1),
        ("latencia", "latencia_media_ciclos_secuenciador", "Latencia de fallo (ciclos Ruby)", 1),
    )
    for nombre, columna, etiqueta, factor in medidas:
        figura, ejes = plt.subplots(1, 3, figsize=(13, 4), constrained_layout=True)
        for protocolo in EVENTOS:
            for modo in MODOS:
                valores = [float(falso[protocolo, h, modo][columna]) * factor for h in HILOS]
                ejes[0].plot(HILOS, valores, "o-", label=f"{protocolo} {modo.replace('_', ' ')}")
            for eje, n in zip(ejes[1:], TAMANOS):
                valores = [float(gemm[protocolo, h, n][columna]) * factor for h in HILOS]
                eje.plot(HILOS, valores, "o-", label=protocolo)
        for eje, titulo in zip(ejes, ("Falso compartido", "GEMM N=64", "GEMM N=128")):
            eje.set(title=titulo, xlabel="Nucleos", ylabel=etiqueta, xticks=list(HILOS))
            if nombre in {"invalidaciones", "trafico"}:
                eje.set_yscale("symlog", linthresh=1)
            eje.legend()
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
