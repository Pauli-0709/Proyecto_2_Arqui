#!/usr/bin/env python3
# La proxima linea le indica al OS (kernel) que el archivo de texto debe ser ejecutado utilizando el interprete Bash


"""Extraer el primer bloque de ROI de las corridas actuales de E2 y E3."""

# Bibliotecas
# Biblioteca para analizar argumentos de la linea de comandos
import argparse
# Biblioteca para manejar y exportar archivos CSV
import csv
# Biblioteca que ayuda con las expresiones regulares
import re
# Biblioteca para las entradas, salidas y errores
import sys
# Importar las bibliotecas para alta precision (decimal/invalid operation)
from decimal import Decimal, InvalidOperation
# Importar biblioteca path para el manejo de objetos
from pathlib import Path

#-----------------------------------------------------------------------

# Nombres usados por las corridas de un nucleo.
METRICAS = ("simInsts", "system.cpu.numCycles", "simTicks", "simFreq")
INICIO = "---------- Begin Simulation Statistics ----------"
FIN = "---------- End Simulation Statistics   ----------"

#-------------------------------------------------------------------------------

# Funcion principal para leer y validar el bloque ROI de un archivo
def leer_roi(ruta):
    """Leer el primer bloque sin sustituirlo por un bloque posterior."""
    # Variable para almacenar las metricas extraidas
    valores = {}
    # Variable para verificar si se esta dentro del bloque de interes (flag)
    dentro = False
    # Variable para verificar si se termino de forma correcta el bloque de interes (flag)
    completo = False



    # Apertura del archivo en su ruta y en modo lectura
    with ruta.open(encoding="utf-8") as archivo:
        # Blucle para recorrer todas las lineas del archivo
        for linea in archivo:
            # Borra los espacios en blanco al inicio y al final
            texto = linea.strip()



            # Detectar el comienzo del primer bloque de estadisticas
            if texto == INICIO:
                # Verificar la flag, declarada anteriormente
                if dentro:
                    # Ejecuta el error en pantalla de que el bloque no se cerro correctamente
                    raise ValueError(f"{ruta}: primer bloque sin cierre")
                # Actualiza la flag
                dentro = True
                continue


            # Terminar al cerrar el primer bloque
            # If para evaluar si la linea actual es el final
            if texto == FIN:
                # Se activa, si se llego al final
                if not dentro:
                    # Se ejecuta el error de un cierre inesperado sin inicio previo
                    raise ValueError(f"{ruta}: cierre sin inicio")
                # Actualizar la flag
                completo = True
                break  # Excluir los bloques que contienen trabajo posterior

            # El IF se activa si la flag es false, y solo se da cuando se esta afuera del bloque que se necesita
            if not dentro:
                continue

            # Quitar comentarios y separar el nombre de su valor
            partes = texto.split("#", 1)[0].split()
            if not partes or partes[0] not in METRICAS:
                continue

            # Extrae el nombre de la metrica asignandole el primer elemento de la lista
            nombre = partes[0]

            # Se comprueba si la metrica esta duplicada o si falta su valor numerico
            if nombre in valores or len(partes) < 2:
                # Ejecuta el error por estar duplicada o incompleta
                raise ValueError(f"{ruta}: metrica duplicada o incompleta: {nombre}")

            # Decimal permite validar el numero sin perder precision entera
            try:
                # Convierte el texto del segundo elemento en un objeto decimal
                valor = Decimal(partes[1])
            # Se captura la excepcion especifica si en este caso el texto no es un numero valido
            except InvalidOperation:
                # Ejecuta el error de valor no numerico
                raise ValueError(f"{ruta}: valor no numerico: {nombre}") from None

            # Estas cuatro metricas deben ser enteros positivos y finitos
            if (not valor.is_finite() or valor <= 0 or valor != valor.to_integral_value()):
                # Genera un error si alguna de las metricas fallo
                raise ValueError(f"{ruta}: valor invalido: {nombre}")

            # Almacena el valor validado convertido a entero en la variable
            valores[nombre] = int(valor)

    # No aceptar archivos incompletos ni inventar valores faltantes
    if not completo:
        # Genera el error del archivo incompleto
        raise ValueError(f"{ruta}: falta el primer bloque completo")


    # Calcula que metricas obligatorias faltan en la variable
    faltantes = set(METRICAS) - valores.keys()
    if faltantes:
        # Genera el error indicando cuales metricas no se encontraron
        raise ValueError(f"{ruta}: faltan metricas: {', '.join(sorted(faltantes))}")

    return valores

#--------------------------------------------------------------------------------------------------

# FUncion para procesar un archivo y extraer una fila de datos.
def extraer_fila(ruta):
    """Exigir evidencia de validacion antes de exportar una corrida."""

    # Obtener la carpeta que contiene el archivo stats.txt.
    carpeta = ruta.parent

    # Leer las evidencias generadas por el lanzador.
    validacion = (carpeta / "validation.txt").read_text(encoding="utf-8")
    registro = (carpeta / "run.log").read_text(encoding="utf-8")

    # Comprobar que el archivo de validacion no este vacio.
    if not validacion.strip():
        # Detener la extraccion si falta la confirmacion de validacion.
        raise ValueError(f"{carpeta}: validation.txt vacio")

    # Comprobar que la multiplicacion termino con resultados correctos.
    if not re.search(r"\bCHECK=PASS\s+errores=0\b", registro):
        # Detener la extraccion si no aparece la comprobacion esperada.
        raise ValueError(f"{carpeta}: falta CHECK=PASS con errores=0")

    # Extraer las metricas del primer bloque completo de la ROI.
    valores = leer_roi(ruta)

    # Calcular el tiempo simulado a partir de ticks y frecuencia.
    segundos = Decimal(valores["simTicks"]) / Decimal(valores["simFreq"])

    # Construir una fila con la ruta, el bloque y las metricas.
    return {"ruta": ruta.as_posix(), "roi_block": 1, **valores, "roi_seconds": str(segundos),}
#----------------------------------------------------------------------------------------------------




# Funcion principal
def main():
    # Aceptar un stats.txt individual o una carpeta de resultados
    parser = argparse.ArgumentParser(description=__doc__)
    # Anade un argumento posicional obligatorio para el parser
    parser.add_argument("entrada", type=Path, help="Archivo stats.txt o carpeta")
    # Parsea los argumentos introducidos  y los guardara en la variable
    args = parser.parse_args()

    try:
        # Comprueba si la ruta introducida es una carpeta valida
        if args.entrada.is_dir():
            # Busca recursivamente todos los archivos stats.txt dentro de la carpeta y los ordena
            archivos = sorted(args.entrada.rglob("stats.txt"))
        # Se comprueba la ruta y se llama stats.txt
        elif args.entrada.is_file() and args.entrada.name == "stats.txt":
            # Genera una lista que contiene el archivo
            archivos = [args.entrada]
        else:
            # Genera un error debido a la entrada
            raise ValueError("La entrada debe ser un stats.txt o una carpeta existente")

        # Por si la lista esta vacia
        if not archivos:
            # Genera el error si esta vacio
            raise ValueError("No se encontraron archivos stats.txt")


        # Validar todas las corridas antes de imprimir el CSV
        # Si una falla, no imprimir filas parciales
        filas = [extraer_fila(ruta) for ruta in archivos]

    # Captura cualquier excepcion de tipo OSError o ValueError se que pudo haber generado
    except (OSError, ValueError) as error:
        # IMprime el error correspondiente
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    # Reservar stdout para el CSV y stderr para el mensaje de comprobacion
    # Define la lista ordenada con los nombres de las columnas para el archivo CSV
    columnas = ["ruta", "roi_block", *METRICAS, "roi_seconds"]
    # Se incia un escritor para el CSV basado en diccionarios (DictWriter)
    escritor = csv.DictWriter(sys.stdout, fieldnames=columnas, lineterminator="\n")
    # Escribe la linea de cabeceras
    escritor.writeheader()
    # Escribe todas las filas
    escritor.writerows(filas)

    # Impresion en pantalla del final del script para la verificacion de los resultados
    print(f"EXTRACCION_OK CORRIDAS={len(filas)} BLOQUE_ROI=1", file=sys.stderr,)
    return 0


# Ejecutar main solamente cuando se llama este archivo directamente
# Comprueba si el script se esta ejecutando directamente como programa principal
if __name__ == "__main__":
    # Ejecuta la funcion main y pasa su valor de retorno como codigo de salida de sys.exit
    sys.exit(main())
