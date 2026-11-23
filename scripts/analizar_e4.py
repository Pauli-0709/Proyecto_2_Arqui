#!/usr/bin/env python3
"""E4: speedup, eficiencia, fraccion serial (Amdahl) y evidencia de memoria/balance.

Lee SOLO el primer bloque de stats.txt (la ROI). Genera en results/e4/summary:
CSV de metricas y por nucleo, resumen Markdown, hashes de los stats y figuras PNG/PDF.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import math
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

from stats_gem5 import (CICLOS, CICLOS_NUCLEO, L1D_ACCESOS, L1D_FALLOS, L2_ACCESOS,
                        MISS_L2, por_nucleo, primer_bloque, primero_presente)

RUTA = re.compile(r"n(?P<n>\d+)[/\\]nucleos(?P<c>\d+)$")


def dividir(a: float, b: float) -> float:
    return a / b if b and not math.isnan(b) else math.nan


@dataclass
class Corrida:
    n: int
    nucleos: int
    tiempo_s: float
    ciclos: float
    instrucciones: float
    fallos_l2: float
    accesos_l2: float = math.nan
    fallos_l1d: float = math.nan
    accesos_l1d: float = math.nan
    ciclos_nucleo: dict[int, float] = field(default_factory=dict)
    tiempo_real_s: float = math.nan
    speedup: float = math.nan
    eficiencia: float = math.nan
    fraccion_serial: float = math.nan

    @property
    def ipc_agregado(self) -> float:
        return self.instrucciones / self.ciclos if self.ciclos else math.nan

    @property
    def tasa_l1d(self) -> float:
        return dividir(self.fallos_l1d, self.accesos_l1d)

    @property
    def tasa_l2(self) -> float:
        return dividir(self.fallos_l2, self.accesos_l2)

    @property
    def desbalance(self) -> float:
        """(max - min) / max de los ciclos por nucleo; 0 = perfectamente balanceado."""
        if not self.ciclos_nucleo:
            return math.nan
        valores = self.ciclos_nucleo.values()
        return dividir(max(valores) - min(valores), max(valores))


# ---- Lectura ------------------------------------------------------------------
def leer_tiempo_real(directorio: Path) -> float:
    ruta = directorio / "tiempo_real_s.txt"
    try:
        return float(ruta.read_text().strip())
    except (OSError, ValueError):
        return math.nan


def leer_corrida(directorio: Path) -> Corrida:
    m = RUTA.search(directorio.as_posix())
    if m is None:
        raise ValueError(f"ruta inesperada: {directorio}")
    stats = primer_bloque(directorio / "stats.txt")
    ciclos = max((v for k, v in stats.items() if CICLOS.match(k)), default=math.nan)
    fallos = por_nucleo(stats, L1D_FALLOS)
    accesos = por_nucleo(stats, L1D_ACCESOS)
    return Corrida(
        n=int(m["n"]), nucleos=int(m["c"]), tiempo_s=stats["simSeconds"],
        ciclos=ciclos, instrucciones=stats.get("simInsts", math.nan),
        fallos_l2=primero_presente(stats, MISS_L2),
        accesos_l2=primero_presente(stats, L2_ACCESOS),
        fallos_l1d=sum(fallos.values()) if fallos else math.nan,
        accesos_l1d=sum(accesos.values()) if accesos else math.nan,
        ciclos_nucleo=por_nucleo(stats, CICLOS_NUCLEO),
        tiempo_real_s=leer_tiempo_real(directorio),
    )


def es_valida(directorio: Path) -> bool:
    val = directorio / "validation.txt"
    return val.exists() and "estado=PASS" in val.read_text()


# ---- Modelo (ley de Amdahl) ---------------------------------------------------
def amdahl(f: float, n: float) -> float:
    return 1 / (f + (1 - f) / n)


def fraccion_serial(speedup: float, n: int) -> float:
    """Despeja f de S = 1 / (f + (1-f)/n)."""
    if n == 1 or speedup <= 0:
        return math.nan
    return (1 / speedup - 1 / n) / (1 - 1 / n)


def ajuste_amdahl(grupo: list[Corrida]) -> float:
    """f por minimos cuadrados sobre 1/S = f + (1-f)/n  ->  (y-x) = f(1-x)."""
    num = den = 0.0
    for c in grupo:
        if c.nucleos > 1:
            x, y = 1 / c.nucleos, 1 / c.speedup
            num += (y - x) * (1 - x)
            den += (1 - x) ** 2
    return num / den if den else math.nan


def desviacion_modelo(grupo: list[Corrida], f: float) -> float:
    """Maxima desviacion relativa |S_modelo - S_medido| / S_medido (mide si Amdahl describe los datos)."""
    return max((abs(amdahl(f, c.nucleos) - c.speedup) / c.speedup
                for c in grupo if c.nucleos > 1), default=math.nan)


def completar_metricas(grupo: list[Corrida]) -> float:
    base = next((c for c in grupo if c.nucleos == 1), None)
    if base is None:
        sys.exit(f"Falta la corrida de 1 nucleo para N={grupo[0].n}")
    for c in grupo:
        c.speedup = base.tiempo_s / c.tiempo_s
        c.eficiencia = c.speedup / c.nucleos
        c.fraccion_serial = fraccion_serial(c.speedup, c.nucleos)
    return ajuste_amdahl(grupo)


def agrupar(corridas: list[Corrida]) -> dict[int, list[Corrida]]:
    return {n: sorted((c for c in corridas if c.n == n), key=lambda c: c.nucleos)
            for n in sorted({c.n for c in corridas})}


def analizar(raiz: Path) -> tuple[list[Corrida], dict[int, float]]:
    corridas = []
    for stats in sorted(raiz.glob("n*/nucleos*/stats.txt")):
        if es_valida(stats.parent):
            corridas.append(leer_corrida(stats.parent))
        else:
            print(f"AVISO: {stats.parent} no paso la validacion; se omite", file=sys.stderr)
    if not corridas:
        sys.exit(f"No hay corridas validas en {raiz}")
    ajustes = {n: completar_metricas(g) for n, g in agrupar(corridas).items()}
    return corridas, ajustes


# ---- Salidas ------------------------------------------------------------------
def ordenadas(corridas: list[Corrida]) -> list[Corrida]:
    return sorted(corridas, key=lambda c: (c.n, c.nucleos))


def pct(x: float) -> str:
    return "nan" if math.isnan(x) else f"{100 * x:.2f}%"


def escribir_csv(corridas: list[Corrida], destino: Path) -> None:
    with destino.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["N", "nucleos", "tiempo_s", "ciclos", "instrucciones", "ipc_agregado",
                    "speedup", "eficiencia", "fraccion_serial", "fallos_l2", "accesos_l2",
                    "tasa_fallo_l2", "fallos_l1d", "accesos_l1d", "tasa_fallo_l1d",
                    "ciclos_min", "ciclos_max", "desbalance", "tiempo_real_s"])
        for c in ordenadas(corridas):
            cn = c.ciclos_nucleo.values()
            w.writerow([c.n, c.nucleos, f"{c.tiempo_s:.9e}", int(c.ciclos), int(c.instrucciones),
                        f"{c.ipc_agregado:.4f}", f"{c.speedup:.4f}", f"{c.eficiencia:.4f}",
                        f"{c.fraccion_serial:.4f}", f"{c.fallos_l2:.0f}", f"{c.accesos_l2:.0f}",
                        f"{c.tasa_l2:.6f}", f"{c.fallos_l1d:.0f}", f"{c.accesos_l1d:.0f}",
                        f"{c.tasa_l1d:.6f}", int(min(cn, default=math.nan)) if cn else "nan",
                        int(max(cn)) if cn else "nan", f"{c.desbalance:.4f}", f"{c.tiempo_real_s:.0f}"])


def escribir_por_nucleo(corridas: list[Corrida], destino: Path) -> None:
    with destino.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["N", "nucleos", "cpu", "ciclos"])
        for c in ordenadas(corridas):
            for cpu, ciclos in sorted(c.ciclos_nucleo.items()):
                w.writerow([c.n, c.nucleos, cpu, int(ciclos)])


def escribir_hashes(raiz: Path, corridas: list[Corrida], destino: Path) -> None:
    lineas = []
    for c in ordenadas(corridas):
        ruta = raiz / f"n{c.n}" / f"nucleos{c.nucleos}" / "stats.txt"
        lineas.append(f"{hashlib.sha256(ruta.read_bytes()).hexdigest()}  {ruta.as_posix()}")
    destino.write_text("\n".join(lineas) + "\n")


def escribir_markdown(corridas: list[Corrida], ajustes: dict[int, float], raiz: Path, destino: Path) -> None:
    md = ["## Escalado (primer bloque de stats = ROI)", "",
          "| N | Núcleos | Tiempo (s) | Speedup | Eficiencia | f serial | IPC agregado |",
          "|---|---|---|---|---|---|---|"]
    md += [f"| {c.n} | {c.nucleos} | {c.tiempo_s:.3e} | {c.speedup:.3f} | {c.eficiencia:.3f} | "
           f"{c.fraccion_serial:.4f} | {c.ipc_agregado:.2f} |" for c in ordenadas(corridas)]
    md += ["", "## Memoria y balance", "",
           "| N | Núcleos | Fallo L1D | Accesos L2 | Fallos L2 | Fallo L2 | Desbalance de ciclos |",
           "|---|---|---|---|---|---|---|"]
    md += [f"| {c.n} | {c.nucleos} | {pct(c.tasa_l1d)} | {c.accesos_l2:.0f} | {c.fallos_l2:.0f} | "
           f"{pct(c.tasa_l2)} | {pct(c.desbalance)} |" for c in ordenadas(corridas)]
    md += ["", "## Ajuste de Amdahl (mínimos cuadrados sobre 1/S)", "",
           "| N | f ajustada | Speedup máx. teórico | Desviación máx. del modelo |", "|---|---|---|---|"]
    for n, grupo in agrupar(corridas).items():
        f = ajustes[n]
        md.append(f"| {n} | {f:.4f} | {1 / f:.1f}x | {pct(desviacion_modelo(grupo, f))} |"
                  if f > 0 else f"| {n} | {f:.4f} | n/a | {pct(desviacion_modelo(grupo, f))} |")
    md += ["", "Una desviación grande o una `f serial` por punto que cambia con los núcleos indica que "
               "una fracción serial constante no describe los datos (hay otro factor, p. ej. memoria).", ""]
    parametros = raiz / "parametros.txt"
    if parametros.exists():
        md += ["## Parámetros de la simulación", "", "```", parametros.read_text().rstrip(), "```", ""]
    destino.write_text("\n".join(md))


def guardar(fig, carpeta: Path, nombre: str) -> None:
    import matplotlib.pyplot as plt
    fig.tight_layout()
    for ext in ("png", "pdf"):
        fig.savefig(carpeta / f"{nombre}.{ext}", dpi=200)
    plt.close(fig)


def graficar(corridas: list[Corrida], ajustes: dict[int, float], carpeta: Path) -> None:
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib no esta instalado: se omiten los graficos", file=sys.stderr)
        return
    por_n = agrupar(corridas)
    nucleos = sorted({c.nucleos for c in corridas})

    fig, ax = plt.subplots(figsize=(6, 4.2))
    ax.plot(nucleos, nucleos, "k--", label="Ideal")
    xs = [1 + i * (max(nucleos) - 1) / 50 for i in range(51)]
    for n, g in por_n.items():
        linea, = ax.plot([c.nucleos for c in g], [c.speedup for c in g], "o-", label=f"N={n} (medido)")
        ax.plot(xs, [amdahl(ajustes[n], x) for x in xs], ":", color=linea.get_color(),
                label=f"N={n} Amdahl f={ajustes[n]:.3f}")
    ax.set(xlabel="Núcleos", ylabel="Speedup", title="E4: speedup de GEMM (O3 ancho 2)", xticks=nucleos)
    ax.grid(alpha=0.3); ax.legend(fontsize=8)
    guardar(fig, carpeta, "e4_speedup")

    fig, ax = plt.subplots(figsize=(6, 4.2))
    for n, g in por_n.items():
        ax.plot([c.nucleos for c in g], [c.eficiencia for c in g], "o-", label=f"N={n}")
    ax.set(xlabel="Núcleos", ylabel="Eficiencia (speedup / núcleos)", ylim=(0, 1.05),
           title="E4: eficiencia paralela", xticks=nucleos)
    ax.grid(alpha=0.3); ax.legend()
    guardar(fig, carpeta, "e4_eficiencia")

    fig, ax = plt.subplots(figsize=(6, 4.2))
    for n, g in por_n.items():
        ax.plot([c.nucleos for c in g], [100 * c.tasa_l1d for c in g], "o-", label=f"N={n}")
    ax.set(xlabel="Núcleos", ylabel="Tasa de fallo L1D (%)", title="E4: tasa de fallo de L1D",
           xticks=nucleos, ylim=(0, None))
    ax.grid(alpha=0.3); ax.legend()
    guardar(fig, carpeta, "e4_l1d")

    fig, ejes = plt.subplots(1, len(por_n), figsize=(5 * len(por_n), 4), squeeze=False)
    for ax, (n, g) in zip(ejes[0], por_n.items()):
        mayor = g[-1]
        cpus = sorted(mayor.ciclos_nucleo)
        ax.bar(cpus, [mayor.ciclos_nucleo[i] / 1e6 for i in cpus])
        ax.set(xlabel="Núcleo", ylabel="Ciclos (millones)", xticks=cpus,
               title=f"N={n}, {mayor.nucleos} núcleos: ciclos por núcleo")
        ax.grid(alpha=0.3, axis="y")
    guardar(fig, carpeta, "e4_balance")


def imprimir(corridas: list[Corrida], ajustes: dict[int, float]) -> None:
    print(f"{'N':>5} {'nuc':>4} {'speedup':>8} {'efic.':>7} {'f_serial':>9} "
          f"{'L1D%':>7} {'accesosL2':>10} {'desbal.':>8}")
    for c in ordenadas(corridas):
        print(f"{c.n:>5} {c.nucleos:>4} {c.speedup:>8.3f} {c.eficiencia:>7.3f} "
              f"{c.fraccion_serial:>9.4f} {100 * c.tasa_l1d:>7.2f} {c.accesos_l2:>10.0f} "
              f"{pct(c.desbalance):>8}")
    for n, g in agrupar(corridas).items():
        f = ajustes[n]
        print(f"N={n}: f ajustada = {f:.4f}, speedup maximo teorico = {1 / f:.1f}x, "
              f"desviacion maxima del modelo = {pct(desviacion_modelo(g, f))}")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--raiz", type=Path, default=Path("results/e4"))
    args = ap.parse_args()
    corridas, ajustes = analizar(args.raiz)
    resumen = args.raiz / "summary"
    resumen.mkdir(exist_ok=True)
    escribir_csv(corridas, resumen / "e4_metricas.csv")
    escribir_por_nucleo(corridas, resumen / "e4_por_nucleo.csv")
    escribir_markdown(corridas, ajustes, args.raiz, resumen / "e4_resumen.md")
    escribir_hashes(args.raiz, corridas, resumen / "e4_stats.sha256")
    graficar(corridas, ajustes, resumen)
    imprimir(corridas, ajustes)


if __name__ == "__main__":
    main()
