# Tablero inicial del equipo

| Semana | Tarea | Lidera | Apoyan / dependencia | Evidencia |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Repositorio, carpetas y tablero | Paulina Camacho | Todos | URL, acceso y tarjetas |
| 1 | ARM, compilador, MESI/MOESI y smoke tests | Paulina Camacho | Tomas Campos valida Ruby | Versiones y logs |
| 1 | Cuatro benchmarks y automatización común | Steven Loaiza | Paulina Camacho acuerda interfaz | Fuentes y validación |
| 1 | E1: seis corridas | Todos | Paulina Camacho facilita entorno | CSV, gráficos, ROI |
| 1 | AC1 y AC2 | Cada persona | Individual | PDF de 1-2 páginas |
| 2 | E2: 24 corridas | Paulina Camacho | Programa común de Steven Loaiza | Datos, gráficos, análisis |
| 2 | E3: SVE | Steven Loaiza | Entorno de Paulina Camacho | Datos y vectorización |
| 2 | Avance de E1-E3, 10 minutos | Sary Vargas  organiza | Todos presentan | Gráficos y bloqueos |
| 3 | E4: multiprocesador | Sary Vargas | Benchmark paralelo de Steven Loaiza | Speedup y Amdahl |
| 3 | E5: coherencia | Tomas Campos | Entorno Paulina Camacho y benchmark Steven Loaiza | Matriz completa |
| 3 | E6: mínimo seis configuraciones | Todos | E2-E5 | Costo, tiempo y propuesta |
| 1-4 | AC3 y coordinación | Cada persona | Integración rotativa | Bitácora y tablero |
| 4 | Informe, video, AC4, coevaluación y entrega | Todos | Secciones propias | Entrega comprobada |

# Directrices y notas operativas para la realizacion del proyecto
- Revisar tablero dos veces por semana.

## Seguimiento de tareas

Estados utilizados:
- Pendiente: todavía no se ha iniciado o no hay evidencia publicada en el repositorio.
- En curso: hay trabajo realizado, pero faltan algunas secciones del mismo.
- Completado: la evidencia está publicada en el repositorio  y fue revisada.

Las fechas objetivo se acuerdan con el equipo. Es importante indicar que una tarea no se marca como completada unicamente porque exista 
una carpeta o un script en particular.

| Tarea | Responsable | Estado | Fecha objetivo | Evidencia o criterio de |
| --- | --- | --- | --- | --- |
| Completar estructura del repositorio | Paulina Camacho | Completado | — | src/, configs/, scripts/, results/ y report/ |
| Establecer seguimiento y calendario | Equipo General | En curso | Por acordar | Fechas, estados y revision dos veces por semana |
| Preparar entorno ARM con Docker | Paulina Camacho | Completado | — | docker/, scripts/arm_env.sh y README.md |
| Verificar ejecucion inicial en ARM | Paulina Camacho | Completado | — | results/environment/ |
| Validar GEMM escalar | Steven Loaiza | Completado | — | results/validation/gemm_scalar_native/ y gemm_scalar_n16/ |
| Repetir validacion ARM desde el entorno de Paulina Camacho | Paulina Camacho | Completado | — | results/validation/paulina_gemm_scalar_n16/ |
| Ejecutar y analizar línea base | Todo el equipo | Pendiente | Por acordar | TimingSimple, Minor y O3; N=64 y N=128 |
| Preparar configuracion O3 parametrizable | Paulina Camacho | Completado | — | configs/configuracion_superescalar.sh y configuracion verificada en las 24 corridas |
| Preparar automatizacion y extraccion de las diversas metricas | Paulina Camacho y Steven Loaiza | En curso | Por acordar | Barrido secuencial y verificacion implementados, extraccion de la ROI a CSV pendiente |
| Ejecutar barrido completo | Paulina Camacho | Completado | — | 24 corridas verificadas y publicadas: 12 en la carpeta results/e2/n64/ y 12 en la carpeta results/e2/n128/ |
| Analizar IPC, IQ/ROB y prediccion | Paulina Camacho | Pendiente | Por acordar | CSV y explicacion de los limites del rendimiento |
| Generar graficos y documentar reproduccion del mismo | Paulina Camacho | Pendiente | Por acordar | Graficos, conclusiones y comandos reproducibles |
| Implementar y validar el GEMM SVE en el simulador gem5 | Steven Loaiza | Completado | — | src/gemm_sve.c y results/validation/gemm_sve_suite_o3/: 16 pruebas con CHECK=PASS para N=16 y N=17 |
| Automatizar la validacion funcional de SVE | Steven Loaiza | Completado | — | scripts/test_gemm_sve.sh: ocho longitudes vectoriales, comprobacion de resultados, VL efectivo y estadisticas |
| Verificar las diversas instrucciones vectoriales de SVE | Steven Loaiza | Completado | — | results/validation/gemm_sve_suite_o3/kernel_asm.txt: instrucciones vectoriales de multiplicacion y suma |
| Documentar la validacion y la reproduccion de SVE | Steven Loaiza | Completado | — | docs/validacion_gemm_sve.md y seccion E3 del README.md |
| Desarrollar el experimento E3 | Steven Loaiza | En curso | Por acordar | Implementación, validación funcional y 32 corridas publicadas; CSV, speedup, análisis y gráficos pendientes |
| Preparar y ejecutar el barrido oficial para E3 | Steven Loaiza | Completado | — | results/e3/n64/ y results/e3/n128/: 16 corridas por tamaño, con parejas escalar/SVE bajo el mismo hardware |
| Analizar instrucciones, los ciclos y el speedup para E3 | Steven Loaiza | Pendiente | Por acordar | Metricas de la ROI en CSV y comparacion escalar/SVE para ambos tamanos |
| Generar graficos y conclusiones para E3 | Steven Loaiza | Pendiente | Por acordar | Speedup frente a VL y explicacion de los limites de rendimiento |
| Implementar y validar GEMM paralelo | Steven Loaiza | Pendiente | Por acordar | Reparto por filas, verificacion de resultados y ROI; programa para el experimento E4 |
| Implementar y validar falso compartido | Steven Loaiza | Pendiente | Por acordar | Variantes sin relleno y con separacion de 64 bytes, comprobacion de contadores y ROI para E5 |

## Coordinacion

- Revisar este seguimiento dos veces por semana.
- Acordar las fechas objetivo y registrarlas en formato AAAA-MM-DD.
- Registrar bloqueos y dependencias cuando aparezcan.
- Actualizar estados junto con los commits que aportan evidencia.
- Acordar y registrar quien realiza la integracion cada semana.
- Mantener las responsabilidades generales E3–E6 y AC1–AC4 del tablero inicial.

## Registro de revisiones

Agregar una fila despues de cada revision real del equipo.

| Fecha | Participantes | Avances revisados | Bloqueos y acuerdos | Proxima revision |
| --- | --- | --- | --- | --- |
