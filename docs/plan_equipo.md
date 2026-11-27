# Tablero inicial del equipo

| Semana | Tarea | Lidera | Apoyan / dependencia | Evidencia |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Repositorio, carpetas y tablero | Paulina Camacho | Todos | URL, acceso y tarjetas |
| 1 | ARM, compilador, MESI/MOESI y smoke tests | Paulina Camacho | Tomas Campos valida Ruby | Versiones y logs |
| 1 | Cuatro benchmarks y automatización común | Steven Loaiza | Paulina Camacho acuerda interfaz | Fuentes y validación |
| 1 | E1: seis corridas | Steven Loaiza y Paulina Camacho | Paulina Camacho facilita entorno | CSV, gráficos, ROI |
| 1 | AC1 y AC2 | Cada integrante del equipo | Individual | PDF de 1-2 páginas |
| 2 | E2: 24 corridas | Paulina Camacho | Programa común de Steven Loaiza | Datos, gráficos, análisis |
| 2 | E3: SVE | Steven Loaiza | Entorno de Paulina Camacho | Datos y vectorización |
| 2 | Avance de E1-E3, 10 minutos | Sary Vargas organiza | Todos presentan | Gráficos y bloqueos |
| 3 | E4: multiprocesador | Sary Vargas | Benchmark paralelo de Steven Loaiza | Speedup y Amdahl |
| 3 | E5: coherencia | Tomas Campos | Entorno Paulina Camacho y benchmark Steven Loaiza | Matriz completa |
| 3 | E6: mínimo seis configuraciones | Sary Vargas y Tomas Campos | E2-E5 | Costo, tiempo y propuesta |
| 1-4 | AC3 y coordinación | Cada persona | Integración rotativa | Bitácora y tablero |
| 4 | Informe, video, AC4, coevaluación y entrega | Todos | Secciones propias | Entrega comprobada |

# Directrices y notas operativas para la realización del proyecto
- Revisar el tablero dos veces por semana.

## Seguimiento de tareas

Estados utilizados:
- Pendiente: todavía no se ha iniciado o no hay evidencia publicada en el repositorio.
- En curso: hay trabajo realizado, pero faltan algunas secciones del mismo.
- Completado: la evidencia está publicada en el repositorio y fue revisada.

En primer lugar, es importante mencionar que, para las tareas completadas, se indica la fecha de publicación del avance
en GitHub. A su vez, en las tareas pendientes, se indica la fecha objetivo propuesta. Asimismo, es importante indicar que
una tarea no se marca como completada únicamente porque exista una carpeta o un script en particular.

| Tarea | Responsable | Estado | Fecha objetivo | Evidencia o criterio de |
| --- | --- | --- | --- | --- |
| Completar estructura del repositorio | Paulina Camacho | Completado | 2026-11-07 | src/, configs/, scripts/, results/ y report/ |
| Establecer seguimiento y calendario | Equipo General | Completado | 2026-11-07 | Fechas, estados y revisión dos veces por semana |
| Preparar entorno ARM con Docker | Paulina Camacho | Completado | 2026-11-07 | docker/, scripts/arm_env.sh y README.md |
| Verificar ejecución inicial en ARM | Paulina Camacho | Completado | 2026-11-04 | results/environment/ |
| Validar GEMM escalar | Steven Loaiza | Completado | 2026-11-07 | results/validation/gemm_scalar_native/ y gemm_scalar_n16/ |
| Repetir validación ARM desde el entorno de Paulina Camacho | Paulina Camacho | Completado | 2026-11-07 | results/validation/paulina_gemm_scalar_n16/ |
| Ejecutar y analizar la línea base de experimento E1 | Steven Loaiza y Paulina Camacho | Completado | 2026-11-23 | [Seis corridas](../results/e1/resumen_linea_base.csv), [gráfico de IPC y ciclos](../results/e1/grafico_linea_base.png) e [informe y reproducción](../report/e1.md). |
| Preparar la configuración O3 parametrizable | Paulina Camacho | Completado | 2026-11-08 | Se publicó la configuración para el superescalar y se usó en las 24 corridas correspondientes para el experimento E2. |
| Preparar la automatización y la extracción de las diversas métricas | Paulina Camacho y Steven Loaiza | En curso | 2026-11-21 | [Extractor común de ROI](../scripts/parse_stats.py), [resumen de E2](../scripts/resumir_e2.py), [CSV de E2](../results/e2/summary/) y [CSV de E3](../results/e3/summary/). |
| Ejecutar el barrido completo | Paulina Camacho | Completado | 2026-11-08 | Se publicaron las diferentes 24 corridas del experimento E2, 12 para un tamaño de N=64 y 12 para un tamaño de N=128. |
| Analizar el IPC, el IQ/ROB y la predicción | Paulina Camacho | Completado | 2026-11-21 | [Análisis de IPC, ocupación de IQ y ROB y fallos de predicción](experimento_superescalar.md) y [CSV de las 24 configuraciones](../results/e2/summary/). |
| Generar los gráficos correspondientes y documentar la reproducción del experimento E2 | Paulina Camacho | Completado | 2026-11-21 | [Gráfico de IPC](../results/e2/figures/e2_ipc.png), [gráfico de ocupación](../results/e2/figures/e2_ocupacion.png) y [script de reproducción](../scripts/reproducir_e2.sh). |
| Implementar y validar el GEMM SVE en el simulador gem5 | Steven Loaiza | Completado | 2026-11-10 | src/gemm_sve.c y results/validation/gemm_sve_suite_o3/: 16 pruebas con CHECK=PASS para N=16 y N=17 |
| Automatizar la validación funcional de SVE | Steven Loaiza | Completado | 2026-11-10 | scripts/test_gemm_sve.sh: ocho longitudes vectoriales, comprobación de resultados, VL efectivo y estadísticas |
| Verificar las diversas instrucciones vectoriales de SVE | Steven Loaiza | Completado | 2026-11-10 | results/validation/gemm_sve_suite_o3/kernel_asm.txt: instrucciones vectoriales de multiplicación y suma |
| Documentar la validación y la reproducción de SVE | Steven Loaiza | Completado | 2026-11-19 | [Guía de validación](validacion_gemm_sve.md). Se documentó la prueba ejecutada en el simulador gem5 y la comprobación con el uso del emulador QEMU para un tamaño de N=16; el mismo generó el mensaje de `CHECK=PASS` y 0 errores. Además, la ejecución nativa en ARM64 con SVE queda pendiente, puesto que no se cuenta con un ordenador con procesador ARM. |
| Desarrollar el experimento E3 | Steven Loaiza | Completado | 2026-11-19 | Se probaron las 32 corridas correspondientes. Se documentaron los comandos para repetirlas y las conclusiones de las mismas. |
| Preparar y ejecutar el barrido oficial para E3 | Steven Loaiza | Completado | 2026-11-11 | results/e3/n64/ y results/e3/n128/: 16 corridas por tamaño, con parejas escalar/SVE bajo el mismo hardware |
| Implementar y validar el extractor de ROI | Steven Loaiza | Completado | 2026-11-19 | [Guía de extracción](extraccion_roi.md). Se comprobó la extracción para las 32 corridas ejecutadas del experimento E3 y se probó `--solo-globales` con el uso de GEMM paralelo de 4 hilos y el falso compartido con MESI sin relleno. |
| Generar CSV y calcular speedup de E3 | Steven Loaiza | Completado | 2026-11-12 | scripts/resumir_e3.py y results/e3/summary/: 32 corridas y 16 comparaciones escalar/SVE |
| Analizar las instrucciones, los ciclos y el speedup para el experimento E3 | Steven Loaiza | Completado | 2026-11-19 | Se documentaron las 16 comparaciones correspondientes y se analizó la caída de rendimiento entre un VL=512 y un VL=640 para un tamaño de N=128. |
| Generar los gráficos y las conclusiones para el experimento E3 | Steven Loaiza | Completado | 2026-11-19 | Se publicó el gráfico y se terminaron las conclusiones correspondientes, que se pueden visualizar en: `docs/experimento_vectorial.md`. |
| Implementar y validar el GEMM paralelo | Steven Loaiza | Completado | 2026-11-18 | [Guía de prueba](gemm_paralelo.md). Las 4 corridas con un tamaño de N=16 y 1, 2, 4 y 8 hilos dieron el mensaje de `CHECK=PASS`. [Evidencia publicada](../results/validation/gemm_paralelo_n16.BJhgEJ/). |
| Implementar y validar el falso compartido | Steven Loaiza | Completado | 2026-11-18 | [Guía de prueba](falso_compartido.md). Las 4 corridas con Ruby dieron el mensaje de `CHECK=PASS` con 2 núcleos, MESI y MOESI, con y sin relleno. [Evidencia publicada](../results/validation/falso_compartido_n2.0e1qLs/). |
| Repetir la validación del GEMM paralelo para el experimento E4 | Sary Vargas | Completado | 2026-11-23 | [Validación de N=16](../results/validation/gemm_paralelo_n16.SxJQKd/) con 1, 2, 4 y 8 hilos. Las pruebas nativas y en gem5 dieron `CHECK=PASS`. |
| Automatizar y ejecutar el barrido multiprocesador del experimento E4 | Sary Vargas | Completado | 2026-11-23 | [Script del barrido](../scripts/barrido_multiprocesador.sh) y [ocho corridas base](../results/e4/) para N=64 y N=128, con 1, 2, 4 y 8 núcleos ArmO3 de ancho de emisión 2. |
| Calcular el speedup, la eficiencia, los fallos de L2 y la fracción serial de E4 | Sary Vargas | Completado | 2026-11-23 | [CSV de métricas](../results/e4/summary/e4_metricas.csv), [resumen con el ajuste de Amdahl](../results/e4/summary/e4_resumen.md) y [gráfico de speedup medido contra el ideal](../results/e4/summary/e4_speedup.png). |
| Comparar el GEMM base con la variante i-k-j | Sary Vargas | Completado | 2026-11-23 | [Ocho corridas de la variante](../results/e4_ikj/) y [comparación de tiempos y caché](../results/e4_comparacion/e4_comparacion.md). Para N=128 y 8 núcleos, la variante fue 2,40 veces más rápida que el GEMM base. |
| Publicar la reproducción del experimento E4 con un solo comando | Sary Vargas | Completado | 2026-11-23 | [Script de reproducción](../scripts/reproducir_e4.sh) y [registro de la validación y regeneración del análisis](../results/e4_reproduccion/reproducir.log). |
| Definir el modelo de costo y las 12 configuraciones del experimento E6 | Sary Vargas | Completado | 2026-11-27 | [Modelo de costo](../scripts/modelo_costo.py) y [CSV de configuraciones](../configs/e6_configuraciones.csv): 12 configuraciones con costo entre 5 y 30, todas dentro del presupuesto de 32. Costo = núcleos × (ancho de emisión/2 + VL/128). |
| Implementar y validar el GEMM paralelo con SVE para E6 | Sary Vargas | Completado | 2026-11-27 | [Fuente `gemm_paralelo_sve.c`](../src/gemm_paralelo_sve.c): archivo nuevo que no modifica los kernels existentes. Cada corrida dio `CHECK=PASS` con 0 errores y se verificaron las instrucciones SVE en el ensamblador. |
| Automatizar y ejecutar el barrido del experimento E6 | Sary Vargas | Completado | 2026-11-27 | [Script del barrido](../scripts/barrido_integracion.sh) y corridas de las 12 configuraciones en [results/e6/](../results/e6/) para N=128 y N=256 (24 corridas). |
| Analizar el tiempo, el rendimiento/costo y el frente de Pareto de E6 | Sary Vargas | Completado | 2026-11-27 | [Script de análisis](../scripts/analizar_e6.py) y resúmenes en [results/e6/](../results/e6/). Para N=128, la más rápida fue c09 (0,1485 ms, costo 30) y la mejor por rendimiento/costo fue c01 (costo 5). |
| Analizar la sensibilidad de E6 (N=256 y presupuesto de 16) | Sary Vargas | Completado | 2026-11-27 | Para N=256, c09 y c05 empataron en tiempo (1,58 ms). Con presupuesto de 16, la más rápida fue c11 (0,1607 ms, costo 15). Detalle en [report/e6.md](../report/e6.md). |
| Ejecutar el control de alineamiento de memoria en E6 | Sary Vargas | Completado | 2026-11-27 | [Resultados del control](../results/e6_control/): c01 con alineamiento tardó 0,4023 ms y con `malloc`, 0,7144 ms. El alineamiento influye, pero no explica por completo la diferencia de c01 contra E3 (0,4608 ms); se documentó como limitación. |
| Publicar la reproducción del experimento E6 con un solo comando | Sary Vargas | Completado | 2026-11-27 | [Script de reproducción](../scripts/reproducir_e6.sh) con validación y registro de hashes. |
| Documentar E6 e integrar la propuesta final del grupo | Sary Vargas y Tomas Campos | En curso | 2026-11-29 | [README de E6](e6_exploracion_presupuesto.md) y [sección del informe](../report/e6.md). Propuesta: c03 (2 núcleos, ancho 2, VL=512, costo 10). Falta que Tomas Campos confirme la propuesta y que se integre al informe IEEE grupal. |

## Coordinación

- Revisar este seguimiento dos veces por semana.
- Acordar las fechas objetivo y registrarlas en formato AAAA-MM-DD.
- Registrar bloqueos y dependencias cuando aparezcan.
- Actualizar estados junto con los commits que aportan evidencia.
- Acordar y registrar quién realiza la integración cada semana.
- Mantener las responsabilidades generales E3–E6 y AC1–AC4 del tablero inicial.

## Calendario de seguimiento del equipo

| Fecha | Actividad | Estado | Evidencia o tema por revisar |
| --- | --- | --- | --- |
| 2026-11-08 | Publicación del barrido del experimento E2 | Realizado | Se publicaron las 24 corridas correspondientes, 12 para un tamaño de N=64 y 12 para un tamaño de N=128. |
| 2026-11-12 | Publicación de los resultados del experimento E3 | Realizado | Se publicaron los diversos CSV y el gráfico de speedup correspondiente. |
| 2026-11-19 | Cierre del análisis del experimento E3 | Realizado | Se publicaron el comando del barrido completo y las conclusiones. |
| 2026-11-23 | Revisión de avances del equipo | Realizado | Se revisarán los avances de los experimentos E2 a E5 y se acordarán los pendientes del informe. |
| 2026-11-23 | Publicación de los resultados del experimento E4 | Realizado | Sary Vargas publicó las 16 corridas, las métricas, el ajuste de Amdahl, los distintos gráficos y el script de reproducción correspondiente. |
| 2026-11-26 | Revisión de resultados para el informe | Por hacer | Se revisarán las métricas y los gráficos del experimento E2 y se comprobará que el informe incluya los resultados del experimento de E3. |
| 2026-11-27 | Publicación de los resultados del experimento E6 | Realizado | Sary Vargas publicó las 24 corridas de las 12 configuraciones, el análisis de Pareto y rendimiento/costo, la sensibilidad, el control de alineamiento y el script de reproducción correspondiente. |
| 2026-11-29 | Revisión final del proyecto | Por hacer | Se revisarán el informe, el video y el repositorio antes de la entrega. |
| 2026-11-30 | Entrega del proyecto | Por hacer | Se entregarán los archivos y enlaces solicitados. |
