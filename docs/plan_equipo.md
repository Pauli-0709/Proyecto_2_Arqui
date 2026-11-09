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
| Preparar configuracion O3 parametrizable | Paulina Camacho | Completado, evidencia en configs/configuracion_superescalar.sh y validación con un tamano de N=16 | Por acordar | Configuracion con ancho y ROB verificables |
| Preparar automatizacion y extraccion de las diversas metricas | Paulina Camacho y Steven Loaiza | En curso, barrido implementado, extraccion ROI a CSV pendiente | Por acordar | Barrido y extraccion exclusiva de ROI a CSV |
| Ejecutar barrido completo | Paulina Camacho | En curso, todavia sin corridas oficiales completadas | Por acordar | 24 corridas correctas con configuracion y estadisticas |
| Analizar IPC, IQ/ROB y prediccion | Paulina Camacho | Pendiente | Por acordar | CSV y explicacion de los limites del rendimiento |
| Generar graficos y documentar reproduccion del mismo | Paulina Camacho | Pendiente | Por acordar | Graficos, conclusiones y comandos reproducibles |

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
