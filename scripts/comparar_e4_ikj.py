#!/usr/bin/env python3
"""Compara E4 (kernel de B) contra la variante i-k-j, con la misma configuracion de hardware.

Lee results/e4/summary/e4_metricas.csv y results/e4_ikj/summary/e4_metricas.csv y
genera results/e4_comparacion/ (CSV, tabla Markdown y figura PNG/PDF).
"""
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path


def leer(ruta: Path) -> dict[tuple[int, int], dict[str, float]]:
    if not ruta.exists():
        sys.exit(f"Falta {ruta}: ejecuta antes analizar_e4.py para esa carpeta")
    with ruta.open(newline="") as f:
        return {(int(r["N"]), int(r["nucleos"])): {k: float(v) for k, v in r.items()
                                                     if k not in ("N", "nucleos")}
                for r in csv.DictReader(f)}


def comparar(base: dict, ikj: dict) -> list[dict]:
    filas = []
    for clave in sorted(base.keys() & ikj.keys()):
        b, i = base[clave], ikj[clave]
        filas.append({"N": clave[0], "nucleos": clave[1],
                      "tiempo_base_s": b["tiempo_s"], "tiempo_ikj_s": i["tiempo_s"],
                      "mejora": b["tiempo_s"] / i["tiempo_s"],
                      "speedup_base": b["speedup"], "speedup_ikj": i["speedup"],
                      "l1d_base": b["tasa_fallo_l1d"], "l1d_ikj": i["tasa_fallo_l1d"]})
    if not filas:
        sys.exit("No hay configuraciones comunes entre ambas carpetas")
    return filas


def escribir(filas: list[dict], carpeta: Path) -> None:
    with (carpeta / "e4_comparacion.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(filas[0]))
        w.writeheader()
        w.writerows(filas)
    md = ["| N | Núcleos | Tiempo B (s) | Tiempo i-k-j (s) | Mejora (x) | Speedup B | Speedup i-k-j | L1D B | L1D i-k-j |",
          "|---|---|---|---|---|---|---|---|---|"]
    md += [f"| {r['N']} | {r['nucleos']} | {r['tiempo_base_s']:.3e} | {r['tiempo_ikj_s']:.3e} | "
           f"{r['mejora']:.2f} | {r['speedup_base']:.2f} | {r['speedup_ikj']:.2f} | "
           f"{100 * r['l1d_base']:.1f}% | {100 * r['l1d_ikj']:.1f}% |" for r in filas]
    (carpeta / "e4_comparacion.md").write_text("\n".join(md) + "\n")


def graficar(filas: list[dict], carpeta: Path) -> None:
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib no esta instalado: se omite la figura", file=sys.stderr)
        return
    nucleos = sorted({r["nucleos"] for r in filas})
    fig, ejes = plt.subplots(1, 2, figsize=(11, 4.2))
    for n in sorted({r["N"] for r in filas}):
        g = [r for r in filas if r["N"] == n]
        x = [r["nucleos"] for r in g]
        linea, = ejes[0].plot(x, [r["speedup_base"] for r in g], "o-", label=f"N={n} kernel de B")
        ejes[0].plot(x, [r["speedup_ikj"] for r in g], "s--", color=linea.get_color(), label=f"N={n} i-k-j")
        ejes[1].plot(x, [r["tiempo_base_s"] * 1e3 for r in g], "o-", color=linea.get_color(), label=f"N={n} B")
        ejes[1].plot(x, [r["tiempo_ikj_s"] * 1e3 for r in g], "s--", color=linea.get_color(), label=f"N={n} i-k-j")
    ejes[0].set(xlabel="Núcleos", ylabel="Speedup", title="Speedup", xticks=nucleos)
    ejes[1].set(xlabel="Núcleos", ylabel="Tiempo ROI (ms)", yscale="log", title="Tiempo de la ROI", xticks=nucleos)
    for ax in ejes:
        ax.grid(alpha=0.3); ax.legend(fontsize=7)
    fig.tight_layout()
    for ext in ("png", "pdf"):
        fig.savefig(carpeta / f"e4_comparacion.{ext}", dpi=200)
    plt.close(fig)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--base", type=Path, default=Path("results/e4"))
    ap.add_argument("--ikj", type=Path, default=Path("results/e4_ikj"))
    ap.add_argument("--salida", type=Path, default=Path("results/e4_comparacion"))
    a = ap.parse_args()
    filas = comparar(leer(a.base / "summary" / "e4_metricas.csv"),
                     leer(a.ikj / "summary" / "e4_metricas.csv"))
    a.salida.mkdir(parents=True, exist_ok=True)
    escribir(filas, a.salida)
    graficar(filas, a.salida)
    print((a.salida / "e4_comparacion.md").read_text())


if __name__ == "__main__":
    main()

