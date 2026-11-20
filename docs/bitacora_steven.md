# Bitacora individual de aprendizaje (AC3)

**Estudiante:** Steven Loaiza Valverde

Las fechas va a corresponder a los commits de evidencia realizados en GitHub.

| Fecha | Necesidad de aprendizaje | Estrategia y accion | Tiempo dedicado | Resultado | Evidencia |
| --- | --- | --- | --- | --- | --- |
| 2026-11-07 | La necesidad de aprender a medir solo la multiplicacion en el simulador gem5 | Como primer punto se efectuo la prueba practica. Ademas, se colocaron las marcas de inicio y fin de la region de interes en GEMM escalar y se logro validar el programa en el simulador gem5 para una configuracion ARM. | 2 horas aproximador | Se logro delimitar la multiplicacion para de esta manera poder medirla por separado de la inicializacion y la comprobacion del resultado. | [Validacion de GEMM escalar](https://github.com/Pauli-0709/Proyecto_2_Arqui/commit/575a0983) |
| 2026-11-12 | Se genero la necesidad del poder aprender a comparar el rendimiento de GEMM escalar vs GEMM SVE | Se efectuo la comparacion de datos. Ademas, se extrajeron las metricas del primer bloque de estadisticas y se logro organizar en archivos CSV. | 3 horas aproximadamente | Se logro obtener las metricas de las 32 corridas y el factor de aceleracion de los 16 pares escalar y el SVE. | [Metricas y speedup de E3](https://github.com/Pauli-0709/Proyecto_2_Arqui/commit/74e8f927) |
| 2026-11-19 | Necesidad de aprender a extraer metricas cuando la simulacion llega a utilizar varios nucleos. | Depuracion. En primer lugar, se adapto el extractor que ya se tenia realizado, ademas se corrigio un error de sangria que se presentaba y se logro comparar las salidas del modo nuevo y del original. | 2 horas aproximadamente | Se logro extraer las metricas globales del GEMM paralelo y del falso compartido. Ademas, la corrida escalar del experimento E3 conservo la columna de ciclos del nucleo. | [Actualizacion del extractor](https://github.com/Pauli-0709/Proyecto_2_Arqui/commit/20f7e537) |
| 2026-11-19 | Necesidad de aprender a poder comprobar el resultado del GEMM SVE desde Ubuntu x86_64. | Se efectuo una prueba practica. Se logro compilar el programa para la configuracion de ARM64 y se logro ejecutar con el uso de la herramienta QEMU para un tamano de N=16. | 1 hora aproximadamente | La ejecucion emulada reporto un mensaje de CHECK=PASS y 0 errors. Ademas, la prueba nativa en ARM64 con SVE quedo pendiente por la falta de este equipo en particular. | [Registro de QEMU](https://github.com/Pauli-0709/Proyecto_2_Arqui/blob/main/results/validation/gemm_sve_qemu/n16.log) |

## Uso de IA

Se utilizo la IA como apoyo para preparar los comandos de QEMU y poder revisar la sangria del extractor. Ademas, se verificaron los resultados con una ejecucion del GEMM SVE
para un tamano de N=16 y con pruebas del extractor en 3 corridas almacenadas (el GEMM paralelo, el falso compartido y el GEMM escalar del experimento E3). Ademas, se utilizo
para resolver algunos bugs que se presentaron de sintaxis de los scripts, y del desarrollo del codigos al momento de su ejecucion.

## Balance del aprendizaje

En primer lugar, la prueba practica me permitio comprobar el resultado del programa. Ademas, la comparacion de los archivos CSV me permitio medir de una forma precisa la
aceleracion de SVE. Finalmente, la depuracion y las diversas pruebas del extractor me permitieron incorporar un modo para varios nucleos y de esta forma poder comprobar
que el modo original seguia funcionando correctamente.
