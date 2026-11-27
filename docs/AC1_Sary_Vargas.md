# AC1. Plan de aprendizaje individual: autoevaluación de competencias

**Estudiante:** Sary Vargas
**Fecha:** [AAAA-MM-DD, semana 1]

> **Antes de entregar:** los niveles de esta matriz son una propuesta basada en lo que se observa de tu trabajo (por ejemplo, cuánta ayuda necesitaste para cada herramienta). Cámbialos si tu punto de partida real fue distinto. Esta matriz es el diagnóstico inicial; AC4 la repite al final.

**Escala:** 0 = no conozco el tema. 1 = lo conozco y lo uso con ayuda. 2 = lo uso solo en tareas conocidas. 3 = puedo explicarlo y adaptarlo a casos nuevos.

## 1. Matriz de competencias (diagnóstico inicial)

| # | Competencia | Nivel inicial | Justificación (ejemplo concreto) |
| ---: | --- | :---: | --- |
| 1 | Terminal Linux y scripts bash | 1 | Ejecuto comandos que me dan, pero no sé leer un script largo ni depurar uno |
| 2 | Git y trabajo colaborativo (ramas, push, autoría) | 1 | Hago commit y push, pero no distingo autor de committer ni cómo actualizar mi rama sin afectar a otros |
| 3 | Docker y contenedores | 1 | Lanzo el contenedor del curso con un script, sin entender qué monta ni qué instala |
| 4 | gem5 en modo SE: configurar y ejecutar | 0 | Nunca he lanzado una simulación ni leído un `config.ini` |
| 5 | Región de interés y métricas de `stats.txt` | 0 | No sé qué bloque de estadísticas corresponde a la multiplicación |
| 6 | Microarquitectura superescalar (ancho, ROB, IQ) | 1 | Sé que un núcleo fuera de orden emite varias instrucciones, no por qué se satura el IPC |
| 7 | Vectorización y SVE | 1 | Conozco la idea de SIMD, no he escrito intrínsecos ni relacionado el VL con el rendimiento |
| 8 | Programación paralela con OpenMP | 1 | He usado `#pragma omp parallel for`, sin pensar en el reparto de filas ni el acceso a memoria |
| 9 | Speedup, eficiencia y ley de Amdahl | 1 | Sé las fórmulas, no sé interpretar una fracción serial medida |
| 10 | Jerarquía de caches y coherencia | 1 | Conozco niveles de cache; no sé diagnosticar fallos por conflicto ni falso compartido |
| 11 | Análisis de datos y gráficos con Python | 1 | Puedo leer un CSV; no he automatizado tablas ni figuras para un informe |
| 12 | Redacción técnica y comunicación de resultados | 1 | Redacto con ayuda; me cuesta separar lo medido de lo que solo es una hipótesis |

## 2. Brechas prioritarias (3)

| Prioridad | Brecha | Meta medible | Fecha meta |
| :---: | --- | --- | --- |
| 1 | gem5 en modo SE y métricas de la ROI (competencias 4 y 5) | Lanzar sola un barrido de 8 corridas y comprobar en `config.ini` que el hardware es el pedido | [fecha] |
| 2 | Escalabilidad, Amdahl y caches (competencias 9 y 10) | Explicar con 2 métricas medidas por qué un speedup se aleja del ideal | [fecha] |
| 3 | Reproducibilidad con scripts y git (competencias 1, 2 y 3) | Un solo comando que regenere CSV y gráficos, y commits publicados con mi autoría | [fecha] |

## 3. Plan de acción

| Brecha | Estrategias previstas | Evidencia que guardaré |
| --- | --- | --- |
| 1 | Seguir el tutorial *Learning gem5*; prueba práctica con el GEMM paralelo en N = 16; comparar mi comando con el de un compañero | `command.txt`, `config.ini`, `stats.txt` |
| 2 | Leer Amdahl [1] y Hill y Marty [2]; calcular speedup y eficiencia y comparar con las tasas de fallos | `e4_metricas.csv`, `e4_resumen.md` |
| 3 | Escribir `reproducir_e4.sh`; leer *Pro Git*; revisar `git log` antes de cada push | scripts, historial de git |

## Referencias

[1] G. M. Amdahl, "Validity of the single processor approach to achieving large scale computing capabilities," AFIPS Spring Joint Computer Conf., 1967, pp. 483–485.
[2] M. D. Hill y M. R. Marty, "Amdahl's law in the multicore era," IEEE Computer, vol. 41, no. 7, pp. 33–38, 2008.
