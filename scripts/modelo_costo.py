"""Modelo de costo de E6: costo = nucleos * (ancho/2 + VL/128)."""
import argparse
import csv
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Configuracion:
    id: str
    nucleos: int
    ancho: int
    vl_bits: int
    justificacion: str

    @property
    def costo(self) -> float:
        return costo(self.nucleos, self.ancho, self.vl_bits)


def costo(nucleos: int, ancho: int, vl_bits: int) -> float:
    return nucleos * (ancho / 2 + vl_bits / 128)


def leer_configuraciones(ruta: Path) -> list[Configuracion]:
    with Path(ruta).open(encoding="utf-8", newline="") as archivo:
        return [
            Configuracion(
                fila["id"], int(fila["nucleos"]), int(fila["ancho"]),
                int(fila["vl_bits"]), fila["justificacion"],
            )
            for fila in csv.DictReader(archivo)
        ]


def validar(configuraciones: list[Configuracion], presupuesto: float) -> None:
    ids = [c.id for c in configuraciones]
    if len(set(ids)) != len(ids):
        raise ValueError("hay identificadores repetidos")
    if len(configuraciones) < 6:
        raise ValueError("E6 exige al menos 6 configuraciones")
    for c in configuraciones:
        if c.costo > presupuesto:
            raise ValueError(f"{c.id}: costo {c.costo} supera {presupuesto}")
        if not c.justificacion.strip():
            raise ValueError(f"{c.id}: falta la justificacion")
        if c.vl_bits % 128 or not 128 <= c.vl_bits <= 1024:
            raise ValueError(f"{c.id}: VL invalido")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--validar", nargs=2, metavar=("CSV", "PRESUPUESTO"), required=True)
    args = parser.parse_args()
    try:
        configuraciones = leer_configuraciones(Path(args.validar[0]))
        validar(configuraciones, float(args.validar[1]))
    except (OSError, ValueError, KeyError) as error:
        print(f"ERROR costo: {error}", file=sys.stderr)
        return 1
    for c in configuraciones:
        print(f"{c.id:20s} costo={c.costo:g}")
    print(f"MODELO_COSTO_OK CONFIGURACIONES={len(configuraciones)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
