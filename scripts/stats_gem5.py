"""Lectura de stats.txt de gem5 (primer bloque = region de interes)."""
from __future__ import annotations

import math
import re
from pathlib import Path

SEPARADOR = re.compile(r"-+\s*Begin Simulation Statistics\s*-+")
LINEA = re.compile(r"^(\S+)\s+(\S+)")
CICLOS = re.compile(r"system\.cpu\d*\.numCycles$")
MISS_L2 = ("system.l2.overallMisses::total", "system.l2.demandMisses::total")


def primer_bloque(ruta: Path) -> dict[str, float]:
    """Estadisticas del primer bloque: la ROI (m5_reset_stats -> m5_dump_stats)."""
    bloques = [b for b in SEPARADOR.split(ruta.read_text()) if b.strip()]
    if not bloques:
        raise ValueError(f"{ruta}: sin bloques de estadisticas")
    stats: dict[str, float] = {}
    for linea in bloques[0].splitlines():
        m = LINEA.match(linea)
        if m:
            try:
                stats[m[1]] = float(m[2])
            except ValueError:
                pass
    return stats


def primero_presente(stats: dict[str, float], claves: tuple[str, ...]) -> float:
    return next((stats[k] for k in claves if k in stats), math.nan)
    
    # --- Ampliacion para E4: metricas por nucleo y de memoria --------------------
CICLOS_NUCLEO = re.compile(r"system\.cpu(\d*)\.numCycles$")
L1D_FALLOS = re.compile(r"system\.cpu(\d*)\.dcache\.overallMisses::total$")
L1D_ACCESOS = re.compile(r"system\.cpu(\d*)\.dcache\.overallAccesses::total$")
L2_ACCESOS = ("system.l2.overallAccesses::total", "system.l2.demandAccesses::total")


def por_nucleo(stats: dict[str, float], patron: re.Pattern[str]) -> dict[int, float]:
    """Valores de una estadistica por nucleo. Con 1 nucleo gem5 omite el indice (cpu0 -> 'cpu')."""
    valores: dict[int, float] = {}
    for clave, valor in stats.items():
        m = patron.match(clave)
        if m:
            valores[int(m[1]) if m[1] else 0] = valor
    return valores
