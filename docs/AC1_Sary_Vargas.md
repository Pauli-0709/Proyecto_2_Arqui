# AC1. Plan de aprendizaje individual: autoevaluación de competencias

**Estudiante:** Sary Vargas
**Fecha:** [semana 1]

## 0. Cómo se califica

Escala usada en la matriz:

| Nivel | Significado |
| :---: | --- |
| 0 | No lo he hecho nunca |
| 1 | Lo hago siguiendo instrucciones o con ayuda |
| 2 | Lo hago sola y sé explicar por qué funciona |
| 3 | Puedo depurarlo, adaptarlo y enseñárselo a otra persona |

## 1. Matriz de competencias (diagnóstico inicial)

| # | Competencia | Nivel inicial | Justificación |
| ---: | --- | :---: | --- |
| 1 | Terminal Linux y scripts bash | 2 | Puedo ejecutar comandos desde la terminal Linux |
| 2 | Git y trabajo colaborativo (ramas, push, autoría) | 2 | Puedo hacer commits y trabajar en distintas ramas en el repositorio |
| 3 | Docker y contenedores | 1 | Puedo ejecutar el lanzamiento del contenedor, pero me falta entender a profundidad su funcionamiento |
| 4 | gem5 en modo SE: configurar y ejecutar | 0 | Nunca he utilizado esta herramienta |
| 5 | Región de interés y métricas de `stats.txt` | 1 | Me falta investigar sobre el tema |
| 6 | Microarquitectura superescalar (ancho, ROB, IQ) | 1 | Conocimiento básico; me falta investigar |
| 7 | Vectorización y SVE | 1 | Conocimiento básico; falta investigación |
| 8 | Programación paralela con OpenMP | 1 | Conocimiento básico de la herramienta |
| 9 | Speedup, eficiencia y ley de Amdahl | 1 | Conozco las fórmulas y la teoría, pero me falta investigar más para su aplicación |
| 10 | Jerarquía de cachés y coherencia | 1 | Conocimiento básico de la teoría |
| 11 | Análisis de datos y gráficos con Python | 2 | He utilizado la herramienta |
| 12 | Redacción técnica y comunicación de resultados | 2 | Puedo redactar adecuadamente los resultados técnicos obtenidos; sin embargo, se puede depurar |

## 2. Brechas prioritarias (3)

| Prioridad | Brecha | Meta medible | Fecha meta |
| :---: | --- | --- | --- |
| 1 | gem5 en modo SE y métricas de la ROI (competencias 4 y 5) | Lanzar sola un barrido de 8 corridas y comprobar en `config.ini` que el hardware es el pedido | [Semana 4] |
| 2 | Escalabilidad, Amdahl y cachés (competencias 9 y 10) | Explicar con 2 métricas medidas por qué un speedup se aleja del ideal | [Semana 4] |
| 3 | Reproducibilidad con scripts y git (competencias 1, 2 y 3) | Un solo comando que regenere CSV y gráficos, y commits publicados con mi autoría | [Semana 4] |

## 3. Plan de acción

Cada brecha parte del nivel que puse en la matriz. Las estrategias combinan estudio, práctica sobre el trabajo real del proyecto y contraste con otras personas, y cada una deja una evidencia que se puede revisar.

| Brecha | Nivel actual | Estrategias previstas | Evidencia que guardaré | Cómo sabré que funcionó |
| --- | :---: | --- | --- | --- |
| 1. gem5 en modo SE y métricas de la ROI | Competencia 4: 0<br>Competencia 5: 1 | 1) Seguir el tutorial *Learning gem5* [3] para entender cómo se configura y se lanza una simulación.<br>2) Hacer una prueba práctica con el GEMM paralelo en N = 16 y leer el `config.ini` generado.<br>3) Identificar en `stats.txt` el bloque de la ROI y comparar mi comando con el de un compañero. | `command.txt`, `config.ini`, `stats.txt` | Lanzo sola un barrido de 8 corridas y compruebo en `config.ini` que el hardware coincide con el pedido. |
| 2. Escalabilidad, Amdahl y cachés | Competencia 9: 1<br>Competencia 10: 1 | 1) Leer Amdahl [1] y Hill y Marty [2] para pasar de conocer las fórmulas a saber aplicarlas.<br>2) Calcular speedup, eficiencia y fracción serial con mis propias corridas de E4.<br>3) Comparar los resultados con las tasas de fallos de caché para explicar por qué el speedup se aleja del ideal. | `e4_metricas.csv`, `e4_resumen.md` | Explico con 2 métricas medidas la diferencia entre el speedup medido y el ideal. |
| 3. Reproducibilidad con scripts y git | Competencia 1: 2<br>Competencia 2: 2<br>Competencia 3: 1 | 1) Escribir `reproducir_e4.sh` para que un solo comando regenere CSV y gráficos.<br>2) Leer *Pro Git* [4] sobre ramas y autoría, y revisar `git log` antes de cada push.<br>3) Revisar qué monta e instala el contenedor para entender su funcionamiento. | scripts, historial de git | Un solo comando regenera los resultados y mis commits aparecen publicados con mi autoría. |

## Referencias

[1] G. M. Amdahl, "Validity of the single processor approach to achieving large scale computing capabilities," en *Proc. AFIPS Spring Joint Computer Conf.*, 1967, pp. 483–485.

[2] M. D. Hill y M. R. Marty, "Amdahl's law in the multicore era," *IEEE Computer*, vol. 41, n.º 7, pp. 33–38, 2008.

[3] J. Lowe-Power, "Learning gem5," documentación de gem5. https://www.gem5.org/documentation/learning_gem5/introduction/

[4] S. Chacon y B. Straub, *Pro Git*, 2.ª ed. (en español). https://git-scm.com/book/es/v2
