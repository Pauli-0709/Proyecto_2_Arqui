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

En primer lugar, es importante mencionar que para las tareas completadas, se indica la fecha de publicacion del avance
en GitHub. A su vez, en las tareas pendientes, se indica la fecha objetivo propuesta. Asimismo, es importante indicar que 
una tarea no se marca como completada unicamente porque exista una carpeta o un script en particular.

| Tarea | Responsable | Estado | Fecha objetivo | Evidencia o criterio de |
| --- | --- | --- | --- | --- |
| Completar estructura del repositorio | Paulina Camacho | Completado | — | src/, configs/, scripts/, results/ y report/ |
| Establecer seguimiento y calendario | Equipo General | En curso | Por acordar | Fechas, estados y revision dos veces por semana |
| Preparar entorno ARM con Docker | Paulina Camacho | Completado | — | docker/, scripts/arm_env.sh y README.md |
| Verificar ejecucion inicial en ARM | Paulina Camacho | Completado | — | results/environment/ |
| Validar GEMM escalar | Steven Loaiza | Completado | — | results/validation/gemm_scalar_native/ y gemm_scalar_n16/ |
| Repetir validacion ARM desde el entorno de Paulina Camacho | Paulina Camacho | Completado | — | results/validation/paulina_gemm_scalar_n16/ |
| Ejecutar y analizar línea base | Todo el equipo | Pendiente | Por acordar | TimingSimple, Minor y O3; N=64 y N=128 |
| Preparar la configuracion O3 parametrizable | Paulina Camacho | Completado | 2026-11-08 | Se publico la configuracion para el superescalar y se uso en las 24 corridas correspondientes para el experimento E2. |
| Preparar la automatizacion y la extraccion de las diversas metricas | Paulina Camacho y Steven Loaiza | En curso | Por acordar | [Extractor comun de ROI](../scripts/parse_stats.py), [resumen de E2](../scripts/resumir_e2.py), [CSV de E2](../results/e2/summary/) y [CSV de E3](../results/e3/summary/). |
| Ejecutar el barrido completo | Paulina Camacho | Completado | 2026-11-08 | Se publicaron las diferentes 24 corridas del experimento E2, 12 para un tamano de N=64 y 12 para un tamano de N=128. |
| Analizar el IPC, el IQ/ROB y la prediccion | Paulina Camacho | Completado | 2026-11-21 | [Analisis de IPC, ocupacion de IQ y ROB y fallos de prediccion](experimento_superescalar.md) y [CSV de las 24 configuraciones](../results/e2/summary/). |
| Generar los graficos correspondientes y documentar la reproduccion del experimento E2 | Paulina Camacho | Completado | 2026-11-21 | [Grafico de IPC](../results/e2/figures/e2_ipc.png), [grafico de ocupacion](../results/e2/figures/e2_ocupacion.png) y [script de reproduccion](../scripts/reproducir_e2.sh). |
| Implementar y validar el GEMM SVE en el simulador gem5 | Steven Loaiza | Completado | — | src/gemm_sve.c y results/validation/gemm_sve_suite_o3/: 16 pruebas con CHECK=PASS para N=16 y N=17 |
| Automatizar la validacion funcional de SVE | Steven Loaiza | Completado | — | scripts/test_gemm_sve.sh: ocho longitudes vectoriales, comprobacion de resultados, VL efectivo y estadisticas |
| Verificar las diversas instrucciones vectoriales de SVE | Steven Loaiza | Completado | — | results/validation/gemm_sve_suite_o3/kernel_asm.txt: instrucciones vectoriales de multiplicacion y suma |
| Documentar la validacion y la reproduccion de SVE | Steven Loaiza | Completado | 2026-11-19 | [Guia de validacion](validacion_gemm_sve.md). Se documento la prueba ejecutada en el simulador gem5 y la comprobacion con el uso del emulador QEMU para un tamano de N=16, el mismo genero el mensaje de `CHECK=PASS` y 0 errores. Ademas, la ejecucion nativa en ARM64 con SVE queda pendiente, puesto que no se cuenta con un ordenador con procesador ARM. |
| Desarrollar el experimento E3 | Steven Loaiza | Completado | 2026-11-19 | Se probaron las 32 corridas correspondientes. Se documentaron los comandos para repetirlas y las conclusiones de las mismas. |
| Preparar y ejecutar el barrido oficial para E3 | Steven Loaiza | Completado | — | results/e3/n64/ y results/e3/n128/: 16 corridas por tamaño, con parejas escalar/SVE bajo el mismo hardware |
| Implementar y validar el extractor de ROI | Steven Loaiza | Completado | 2026-11-19 | [Guia de extraccion](extraccion_roi.md). Se comprobo la extraccion para las 32 corridas ejecutadas del experimento E3 y se probo `--solo-globales` con  el uso de GEMM paralelo de 4 hilos y el falso compartido con MESI sin relleno. |
| Generar CSV y calcular speedup de E3 | Steven Loaiza | Completado | — | scripts/resumir_e3.py y results/e3/summary/: 32 corridas y 16 comparaciones escalar/SVE |
| Analizar las instrucciones, los ciclos y el speedup para el experimento E3 | Steven Loaiza | Completado | 2026-11-19 | Se documentaron las 16 comparaciones correspodientes y se analizo la caida de rendimiento entre un VL=512 y un VL=640 para un tamano de N=128. |
| Generar los graficos y las conclusiones para el experimento E3 | Steven Loaiza | Completado | 2026-11-19 | Se publico el grafico  y termino las conclusiones correspondientes y se logran visualizar en: `docs/experimento_vectorial.md`. |
| Implementar y validar el GEMM paralelo | Steven Loaiza | Completado | — | [Guia de prueba](gemm_paralelo.md). Las 4 corridas con un tamano de N=16 y 1, 2, 4 y 8 hilos dieron el mensaje de `CHECK=PASS`. [Evidencia publicada](../results/validation/gemm_paralelo_n16.BJhgEJ/). |
| Implementar y validar el falso compartido | Steven Loaiza | Completado | — | [Guia de prueba](falso_compartido.md). Las 4 corridas con Ruby dieron el mensanje de `CHECK=PASS` con 2 nucleos, MESI y MOESI, con y sin relleno. [Evidencia publicada](../results/validation/falso_compartido_n2.0e1qLs/). |

## Coordinacion

- Revisar este seguimiento dos veces por semana.
- Acordar las fechas objetivo y registrarlas en formato AAAA-MM-DD.
- Registrar bloqueos y dependencias cuando aparezcan.
- Actualizar estados junto con los commits que aportan evidencia.
- Acordar y registrar quien realiza la integracion cada semana.
- Mantener las responsabilidades generales E3–E6 y AC1–AC4 del tablero inicial.

## Calendario de seguimiento del equipo

| Fecha | Actividad | Estado | Evidencia o tema por revisar |
| --- | --- | --- | --- |
| 2026-11-08 | Publicacion del barrido del experimento E2 | Realizado | Se publicaron las 24 corridas correspondientes, 12 para un tamano de N=64 y 12 para un tamano de N=128. |
| 2026-11-12 | Publicacion de los resultados del experimento E3 | Realizado | Se publicaron los diversos CSV y el grafico de speedup correspondiente. |
| 2026-11-19 | Cierre del analisis del experimento E3 | Realizado | Se publicaron el comando del barrido completo y las conclusiones. |
| 2026-11-23 | Revision de avances del equipo | Por hacer | Se revisaran los avances de los experimentos E2 a E5 y se acordaran los pendientes del informe. |
| 2026-11-26 | Revision de resultados para el informe | Por hacer | Se revisaran las metricas y los graficos del experimento E2 y se comprobara que el informe incluya los resultados del experimento de E3. |
| 2026-11-29 | Revision final del proyecto | Por hacer | Se revisaran el informe, el video y el repositorio antes de la entrega. |
| 2026-11-30 | Entrega del proyecto | Por hacer | Se entregaran los archivos y enlaces solicitados. |
