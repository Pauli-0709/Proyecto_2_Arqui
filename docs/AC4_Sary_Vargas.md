
# AC4. Reflexión crítica individual

**Estudiante:** Sary Vargas Zamora
**Fecha:** [semana 4]


## 1. Diagnóstico inicial contra final

Los niveles iniciales son los de la matriz de AC1 y se usa la misma escala de 0 a 3.

| # | Competencia | Inicial | Final | Evidencia del cambio |
| ---: | --- | :---: | :---: | --- |
| 1 | Terminal Linux y scripts bash | 2 | 2 | Sin cambio de nivel, pero afiancé la competencia: escribí `barrido_multiprocesador.sh`, `reproducir_e4.sh` y `reproducir_e6.sh`; detecté y detuve corridas duplicadas con `pgrep` |
| 2 | Git y trabajo colaborativo | 2 | 2 | Sin cambio de nivel, pero afiancé la competencia: corregí la autoría de mis commits y actualicé la rama con `--ff-only` sin tocar archivos ajenos |
| 3 | Docker y contenedores | 1 | 2 | Entendí por qué los procesos de gem5 son del contenedor y necesité `sudo` para cerrarlos |
| 4 | gem5 en modo SE | 0 | 2 | Armé el comando de E4 y E6 y verifiqué el hardware efectivo en `config.ini` |
| 5 | ROI y métricas de `stats.txt` | 1 | 2 | Extraje speedup, eficiencia, fallos de L1D/L2 y desbalance por núcleo |
| 6 | Microarquitectura superescalar | 1 | 2 | Usé los datos de E2 para justificar los anchos 1, 2 y 4 de E6 |
| 7 | Vectorización y SVE | 1 | 2 | Escribí un kernel SVE con OpenMP y comprobé que el binario tiene `fmul`/`fadd` sobre registros `z` |
| 8 | OpenMP | 1 | 2 | Reparto estático de filas; comprobé hilos activos igual a núcleos |
| 9 | Speedup, eficiencia y Amdahl | 1 | 2 | Ajuste de `f` por mínimos cuadrados; interpreté por qué el modelo se desvió 18,49 % con N = 128 |
| 10 | Cachés y coherencia | 1 | 2 | Relacioné 39,14 % de fallos de L1D con el patrón de acceso y comprobé la mejora con la variante i-k-j |
| 11 | Datos y gráficos con Python | 2 | 2 | Sin cambio de nivel, pero afiancé la competencia: escribí analizadores de E4 y E6 que generan CSV, Pareto y resúmenes |
| 12 | Redacción técnica | 2 | 2 | Sin cambio de nivel, pero afiancé la competencia: separé lo medido de las hipótesis y declaré limitaciones |

## 2. Eficacia de cada estrategia (bitácora, AC3)

| Estrategia | ¿Funcionó? | Evidencia |
| --- | --- | --- |
| Práctica con pruebas de humo (N = 16) antes de un barrido largo | **Sí.** Detectó que faltaban parámetros de hardware antes de gastar horas | Corrección del comando de E4 |
| Depuración comparando contra una corrida de referencia | **Sí.** Mostró el `numROBEntries` duplicado y el hardware desalineado con E2 | `command.txt` de E4 |
| Lectura de fuentes (Amdahl, Hill y Marty, Hennessy y Patterson) | **Parcialmente.** Dio el marco, pero solo entendí la desviación de Amdahl al comparar la `f` por número de núcleos | `e4_resumen.md` |
| Consulta a IA verificada con simulaciones | **Sí, con límites.** Aceleró scripts y comandos; sus explicaciones de causa solo las acepté cuando una corrida propia las respaldaba. Dos corridas simultáneas me enseñaron que debía comprobar los procesos antes de lanzar | Repetición completa de E4, validación en E6 |
| Coordinación con compañeros (revisar qué cambiaron antes de subir) | **Sí.** Evitó pisar archivos de otros y mostró que los cambios de E5 no afectaban a E4 | `git diff --stat` |

Lo que no funcionó del todo: lancé un barrido sin comprobar si había otro igual en marcha, y perdí una corrida. Al ver que el tiempo de c01 difería 13 % del de E3, hice un control: cambiar solo la reserva de memoria alineada por `malloc` empeoró c01 1,78 veces. La alineación importa mucho, pero tampoco reproduce el tiempo de E3, y la causa restante sigue sin aislarse; lo declaré como limitación.

## 3. Mejoras propuestas

- Antes de un barrido largo, comprobar procesos y candados (`pgrep`, lock) y registrar el comando en un archivo.
- Añadir un experimento de control por cada hipótesis que escriba (por ejemplo, variar la asociatividad de L1D o el tamaño de la L2).
- Hacer una prueba de equivalencia entre el kernel nuevo y el anterior antes de comparar contra datos antiguos, e imprimir la alineación de las matrices (`puntero % 64`) en cada corrida.
- Para la próxima tecnología nueva: empezar por una prueba mínima (N pequeño) y por un recurso oficial, y escribir la hipótesis y cómo se comprobará antes de medir.

## 4. Aporte a los 2 minutos del video

"Al empezar, mi nivel en gem5 era cero y en leer las estadísticas era básico. Lo que más funcionó fueron las pruebas de humo antes de cada barrido largo y comparar mis corridas contra una de referencia: así encontré que mi hardware no coincidía con el de E2. También aprendí a no afirmar causas que no medí: la caída de eficiencia de E4 la asocié al patrón de acceso, y la variante con otro orden de bucles lo respaldó, pero no probé el mecanismo exacto. Lo que haría distinto es un experimento de control por cada hipótesis."
