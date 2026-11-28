
# AC4. Reflexión crítica individual

**Estudiante:** Sary Vargas Zamora
**Fecha:** [semana 4]


## 1. Diagnóstico inicial contra final

Los niveles iniciales son los de la matriz de AC1 y se usa la misma escala de 0 a 3.

| # | Competencia | Inicial | Final | Evidencia del cambio |
| ---: | --- | :---: | :---: | --- |
| 1 | Terminal Linux y scripts bash | 2 | 3| Aprendí nuevas herramientas y comandos, además del uso a nuevas aplicaciones |
| 2 | Git y trabajo colaborativo | 2 | 2 |Mejoré mis habilidades con la herramienta Git y seguí el plan planteado grupalmente para el trabajo |
| 3 | Docker y contenedores | 1 | 2 | Entendí por qué los procesos de gem5 son del contenedor e hice uso de `sudo` para cerrarlos |
| 4 | gem5 en modo SE | 0 | 2 | Armé el comando de E4 y E6 y verifiqué el hardware efectivo en `config.ini` |
| 5 | ROI y métricas de `stats.txt` | 1 | 2 | Extraje speedup, eficiencia, fallos de L1D/L2 y desbalance por núcleo |
| 6 | Microarquitectura superescalar | 1 | 2 | Usé los datos de E2 para justificar los anchos 1, 2 y 4 de E6 |
| 7 | Vectorización y SVE | 1 | 2 | SE desarrolló un kernel SVE con OpenMP y comprobé que el binario tiene `fmul`/`fadd` sobre registros `z` |
| 8 | OpenMP | 1 | 2 | Reparto estático de filas; comprobé hilos activos igual a núcleos |
| 9 | Speedup, eficiencia y Amdahl | 1 | 2 | Ajuste de `f` por mínimos cuadrados; interpreté por qué el modelo se desvió 18,49 % con N = 128 |
| 10 | Cachés y coherencia | 1 | 2 | Relacioné 39,14 % de fallos de L1D con el patrón de acceso y comprobé la mejora con la variante i-k-j |
| 11 | Datos y gráficos con Python | 2 | 3 | Se escribieron analizadores de E4 y E6 que generan CSV, Pareto y resúmenes |
| 12 | Redacción técnica | 2 | 3 | Se mejoró la redacción, indicando resultados, diseños, limitaciones y conclusiones|

## 2. Eficacia de cada estrategia (bitácora, AC3)

| Estrategia | ¿Funcionó? | Evidencia |
| --- | --- | --- |
| Práctica con pruebas de humo (N = 16) antes de un barrido largo | **Sí.** Se detectó que faltaban parámetros de hardware antes de gastar horas | Corrección del comando de E4 |
| Depuración comparando contra una corrida de referencia | **Sí.** Mostró el `numROBEntries` duplicado y el hardware desalineado con E2 | `command.txt` de E4 |
| Lectura de fuentes (Amdahl, Hill y Marty, Hennessy y Patterson) | **Sí** Se estudió la desviación de Amdahl al comparar la `f` por número de núcleos | `e4_resumen.md` |
| Consulta a IA | **Sí, con límites.**  Se utilizó para revisar códigos y errores de sintaxis | Se utilizó para experimentos E4 y E6 |
| Coordinación con compañeros  | **Sí.** Se mantuvo una comuniacción constante para analizar resultados obtenidos en las diferentes etapas del proyecto y organizar tareas | Se utilizó para experimentos E4 y E6  |

## 3. Mejoras propuestas

- Antes de un barrido largo, comprobar procesos y candados (`pgrep`, lock) y registrar el comando en un archivo.
- Añadir un experimento de control por cada hipótesis que se escriba (por ejemplo, variar la asociatividad de L1D o el tamaño de la L2).
- Hacer una prueba de equivalencia entre el kernel nuevo y el anterior antes de comparar contra datos antiguos, e imprimir la alineación de las matrices en cada corrida.
- Para la próxima tecnología nueva: empezar por una prueba mínima (N pequeño) y por un recurso oficial, y escribir la hipótesis y cómo se comprobará antes de medir.

