"""Analiza E6: tiempo, costo, rendimiento/costo, frente de Pareto y figuras."""
import argparse
import configparser
import csv
import re
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

from modelo_costo import Configuracion, leer_configuraciones
from parse_stats import extraer_fila
from stats_gem5 import primer_bloque

ETAPAS = ("fetchWidth", "decodeWidth", "renameWidth", "dispatchWidth",
          "issueWidth", "wbWidth", "commitWidth")
RE_FALLOS = re.compile(r"^system\.cpu\d*\.dcache\.overallMisses::total$")
RE_ACCESOS = re.compile(r"^system\.cpu\d*\.dcache\.overallAccesses::total$")
COLUMNAS = ["n", "id", "nucleos", "ancho", "vl_bits", "costo", "roi_ms", "rendimiento_por_costo",
            "speedup_vs_base", "l1d_fallos_pct", "instrucciones", "pareto", "dentro_presupuesto"]


def verificar_hardware(carpeta: Path, cfg: Configuracion) -> None:
    """Comprueba en config.ini que la corrida uso lo que dice el CSV."""
    ini = configparser.ConfigParser(interpolation=None)
    ini.optionxform = str
    ini.read(carpeta / "config.ini")
    cpus = [s for s in ini.sections() if ini[s].get("type") == "BaseO3CPU"]
    if len(cpus) != cfg.nucleos:
        raise ValueError(f"{cfg.id}: {len(cpus)} CPU en config.ini, se esperaban {cfg.nucleos}")
    esperados = {etapa: cfg.ancho for etapa in ETAPAS}
    esperados.update(numROBEntries=192, numIQEntries=64, forwardComSize=256)
    for seccion in cpus:
        for parametro, valor in esperados.items():
            if ini[seccion][parametro] != str(valor):
                raise ValueError(f"{cfg.id}: {seccion}.{parametro}={ini[seccion][parametro]}")
        for isa in ini[seccion]["isa"].split():
            if ini[isa]["sve_vl_se"] != str(cfg.vl_bits // 128):
                raise ValueError(f"{cfg.id}: VL efectivo distinto de {cfg.vl_bits}")


def medir(raiz: Path, cfg: Configuracion, n: int) -> dict:
    carpeta = raiz / cfg.id
    validacion = (carpeta / "validation.txt").read_text(encoding="utf-8")
    if not validacion.startswith("estado=PASS\n"):
        raise ValueError(f"corrida sin validar: {carpeta}")
    verificar_hardware(carpeta, cfg)

    ruta = carpeta / "stats.txt"
    globales = extraer_fila(ruta, solo_globales=True)
    stats = primer_bloque(ruta)
    fallos = sum(v for k, v in stats.items() if RE_FALLOS.match(k))
    accesos = sum(v for k, v in stats.items() if RE_ACCESOS.match(k))
    segundos = float(globales["roi_seconds"])
    return dict(
        n=n, id=cfg.id, nucleos=cfg.nucleos, ancho=cfg.ancho, vl_bits=cfg.vl_bits,
        costo=cfg.costo, roi_ms=segundos * 1000,
        rendimiento_por_costo=1.0 / (segundos * 1000 * cfg.costo),
        l1d_fallos_pct=100.0 * fallos / accesos if accesos else 0.0,
        instrucciones=int(float(globales["simInsts"])),
    )


def frente_pareto(filas: list[dict]) -> set[str]:
    """Una configuracion esta en el frente si ninguna otra es mejor o igual en costo y tiempo."""
    frente = set()
    for f in filas:
        dominada = any(
            o["costo"] <= f["costo"] and o["roi_ms"] <= f["roi_ms"]
            and (o["costo"] < f["costo"] or o["roi_ms"] < f["roi_ms"])
            for o in filas
        )
        if not dominada:
            frente.add(f["id"])
    return frente


def figuras(carpeta: Path, filas: list[dict], presupuesto: float, sufijo: str) -> None:
    fig, eje = plt.subplots(figsize=(8, 5), constrained_layout=True)
    for f in filas:
        marca = "o" if f["pareto"] else "x"
        eje.scatter(f["costo"], f["roi_ms"], marker=marca, s=45, color="#2563a6" if f["pareto"] else "0.5")
        eje.annotate(f["id"][:3], (f["costo"], f["roi_ms"]), textcoords="offset points", xytext=(4, 4), fontsize=8)
    frente = sorted((f for f in filas if f["pareto"]), key=lambda f: f["costo"])
    eje.step([f["costo"] for f in frente], [f["roi_ms"] for f in frente], where="post", color="#2563a6", linewidth=1)
    eje.axvline(presupuesto, color="#ad460f", linestyle="--", label=f"Presupuesto {presupuesto:g}")
    eje.set(xlabel="Costo", ylabel="Tiempo de la ROI (ms)", title="E6: tiempo contra costo (o = frente de Pareto)")
    eje.grid(True, color="0.88")
    eje.legend()
    for ext in ("png", "pdf"):
        fig.savefig(carpeta / f"e6_pareto{sufijo}.{ext}", dpi=160)
    plt.close(fig)

    orden = sorted(filas, key=lambda f: -f["rendimiento_por_costo"])
    fig, eje = plt.subplots(figsize=(9, 4.5), constrained_layout=True)
    eje.bar([f["id"][:3] for f in orden], [f["rendimiento_por_costo"] for f in orden], color="#2563a6")
    eje.set(xlabel="Configuracion", ylabel="Rendimiento/costo (1 / (ms x costo))",
            title="E6: rendimiento por unidad de costo")
    eje.grid(True, axis="y", color="0.88")
    for ext in ("png", "pdf"):
        fig.savefig(carpeta / f"e6_rendimiento_costo{sufijo}.{ext}", dpi=160)
    plt.close(fig)


def resumen(ruta: Path, filas: list[dict], n: int, presupuesto: float) -> None:
    viables = [f for f in filas if f["dentro_presupuesto"]]
    mejor_t = min(viables, key=lambda f: f["roi_ms"])
    mejor_pc = max(viables, key=lambda f: f["rendimiento_por_costo"])
    lineas = [
        f"# E6. Resultados N={n}, presupuesto {presupuesto:g}", "",
        f"- Menor tiempo: **{mejor_t['id']}** ({mejor_t['roi_ms']:.4f} ms, costo {mejor_t['costo']:g}).",
        f"- Mejor rendimiento/costo: **{mejor_pc['id']}** ({mejor_pc['rendimiento_por_costo']:.4f}, costo {mejor_pc['costo']:g}).",
        f"- Frente de Pareto: {', '.join(f['id'] for f in filas if f['pareto'])}.", "",
        "| Config | Nucleos | Ancho | VL | Costo | ROI (ms) | Rend/costo | Speedup vs base | L1D fallos (%) | Presupuesto |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :---: |",
    ]
    for f in sorted(filas, key=lambda f: f["roi_ms"]):
        lineas.append(
            f"| {f['id']} | {f['nucleos']} | {f['ancho']} | {f['vl_bits']} | {f['costo']:g} | "
            f"{f['roi_ms']:.4f} | {f['rendimiento_por_costo']:.4f} | {f['speedup_vs_base']:.2f} | "
            f"{f['l1d_fallos_pct']:.1f} | {'si' if f['dentro_presupuesto'] else 'no'} |"
        )
    ruta.write_text("\n".join(lineas) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("carpeta", type=Path, help="p. ej. results/e6/n128")
    parser.add_argument("--csv", type=Path, default=Path("configs/e6_configuraciones.csv"))
    parser.add_argument("--presupuesto", type=float, default=32)
    parser.add_argument("--parcial", action="store_true", help="omite configuraciones sin carpeta")
    args = parser.parse_args()

    n = int(args.carpeta.name.lstrip("n"))
    configuraciones = leer_configuraciones(args.csv)
    if not args.parcial:
        faltan = [c.id for c in configuraciones if not (args.carpeta / c.id).is_dir()]
        if faltan:
            raise ValueError(f"faltan corridas: {faltan}")
    filas = [medir(args.carpeta, c, n) for c in configuraciones if (args.carpeta / c.id).is_dir()]

    base = next((f for f in filas if f["id"] == configuraciones[0].id), filas[0])
    frente = frente_pareto([f for f in filas if f["costo"] <= args.presupuesto])
    for f in filas:
        f["speedup_vs_base"] = base["roi_ms"] / f["roi_ms"]
        f["dentro_presupuesto"] = f["costo"] <= args.presupuesto
        f["pareto"] = f["id"] in frente

    sufijo = "" if args.presupuesto == 32 else f"_p{args.presupuesto:g}"
    salida = args.carpeta / "summary"
    salida.mkdir(exist_ok=True)
    with (salida / f"e6_resultados{sufijo}.csv").open("w", encoding="utf-8", newline="") as archivo:
        tabla = csv.DictWriter(archivo, fieldnames=COLUMNAS)
        tabla.writeheader()
        tabla.writerows(filas)
    viables = [f for f in filas if f["dentro_presupuesto"]]
    figuras(salida, viables, args.presupuesto, sufijo)
    resumen(salida / f"e6_resumen{sufijo}.md", filas, n, args.presupuesto)
    print(f"ANALISIS_E6_OK N={n} PRESUPUESTO={args.presupuesto:g} CONFIGURACIONES={len(filas)}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError) as error:
        raise SystemExit(f"ERROR E6: {error}") from None
