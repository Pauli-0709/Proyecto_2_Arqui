#!/usr/bin/env python3
# La linea anterior permite ejecutar este archivo con Python 3

# Bibliotecas
import csv  # Permite leer el CSV de resultados
import math  # Permite validar numeros y comparar razones
import sys  # Permite informar errores y devolver el codigo de salida
from pathlib import Path  # Permite construir rutas relativas al repositorio
import matplotlib  # Importa la biblioteca para generar las figuras

matplotlib.use("Agg")  # Permite guardar figuras sin abrir una ventana grafica
import matplotlib.pyplot as plt  # Proporciona las funciones de dibujo

RAIZ = Path(__file__).resolve().parents[1]  # Obtiene la raiz del repositorio
ENTRADA = RAIZ / "results/e3/summary/e3_speedup.csv"  # Selecciona las comparaciones
SALIDA = RAIZ / "results/e3/figures"  # Define la carpeta de las figuras
LONGITUDES = tuple(range(128, 1025, 128))  # Define los 8 valores de VL

#----------------------------------------------------------------------------------------------

#FUncion principal
# Valida los datos y genera la figura

def main():
    try:  # Captura problemas de archivos
        with ENTRADA.open(newline="", encoding="utf-8") as archivo:  # Abre el CSV
            filas = list(csv.DictReader(archivo))  # Lee las filas por nombre de columna
        datos = {}  # Almacena los speedups por pareja N y VL
        for fila in filas:  # Recorre las comparaciones
            clave = (int(fila["N"]), int(fila["VL_BITS"]))  # Identifica la configuracion
            if clave in datos:  # Detecta las posibles configuraciones repetidas
                raise ValueError(f"Pareja duplicada: {clave}")  # Rechaza duplicados
            speedup = float(fila["speedup_tiempo"])  # Obtiene el valor que se graficara
            escalar = float(fila["segundos_scalar"])  # Obtiene el tiempo de referencia
            sve = float(fila["segundos_sve"])  # Obtiene el tiempo vectorial
            if not all(math.isfinite(v) and v > 0 for v in (speedup, escalar, sve)):  # Valida los numeros
                raise ValueError(f"Valores invalidos: {clave}")  # Rechaza lso diferentes valores incorrectos
            if not math.isclose(speedup, escalar / sve, rel_tol=1e-9):  # Recalcula la razon temporal
                raise ValueError(f"Speedup incompatible con los tiempos: {clave}")  # Rechaza razones incorrectas
            datos[clave] = speedup  # Conserva el punto validado
        esperadas = {(n, vl) for n in (64, 128) for vl in LONGITUDES}  # Define las 16 parejas esperadas
        if set(datos) != esperadas:  # Comprueba que el barrido este totlamente completo
            raise ValueError("Se requieren N=64 y N=128 con los ocho valores de VL")  # Explica los datos requeridos

        figura, eje = plt.subplots(figsize=(9, 5.5), constrained_layout=True)  # Crea el espacio a graficar y ajusta los margenes
        for n, color, marca in ((64, "#1764ab", "o"), (128, "#b24b16", "s")):  # Define un estilo por tamano
            valores = [datos[(n, vl)] for vl in LONGITUDES]  # Ordena los puntos por VL
            eje.plot(LONGITUDES, valores, color=color, marker=marca, linewidth=2, label=f"N={n}")  # Dibuja los datos medidos
        eje.axhline(1, color="0.4", linestyle="--", linewidth=1, label="Referencia escalar: 1x")  # Marca igualdad de rendimiento.
        eje.set_title("E3: speedup de SVE frente a GEMM escalar\nArmO3CPU, 1 nucleo, 2 GHz, ancho 2, compilacion -O2")  # Identifica el experimento.
        eje.set_xlabel("Longitud vectorial VL (bits)")  # Identifica la variable del barrido
        eje.set_ylabel("Speedup = tiempo escalar / tiempo SVE (veces)")  # Define la magnitud
        eje.set_xticks(LONGITUDES)  # Muestra todas las longitudes evaluadas
        eje.set_ylim(bottom=0)  # Incluye el origen del eje vertical
        eje.grid(True, alpha=0.25)  # Agrega una cuadricula
        eje.legend()  # Identifica las curvas y la referencia escalar
        SALIDA.mkdir(parents=True, exist_ok=True)  # Crea la carpeta de salida si la misma hace falta
        for extension in ("png", "svg"):  # Genera una imagen
            figura.savefig(SALIDA / f"e3_speedup_vs_vl.{extension}", dpi=200)  # Guarda la figura
        plt.close(figura)  # Libera la memoria de la figura
    except (OSError, ValueError, KeyError) as error:  # Captura errores de archivos, valores o columnas
        print(f"ERROR: {error}", file=sys.stderr)  # Imprime el error
        return 1
    print("GRAFICO_E3_OK PAREJAS=16 FORMATOS=png,svg")  # Confirma la generacion de ambos archivos
    return 0


if __name__ == "__main__":  # Ejecuta el programa solo al llamarlo
    sys.exit(main())
