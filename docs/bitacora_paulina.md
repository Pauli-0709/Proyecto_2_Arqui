# Bitacora de aprendizaje de Paulina Camacho

**Proyecto:** Arquitecturas paralelas para la multiplicacion de matrices en el simulador gem5.
**Responsabilidad:** Mi responsabilidad general fue el de preparar el entorno ARM del grupo de trabajo y liderar el experimento E2.
**Registro actualizado al:** 21 de noviembre de 2026.

## Semana 1 - Del 2 al 8 de noviembre

### 3 de noviembre - Organizacion del repositorio

- **Necesidad:** necesitaba que los 4 integrantes pudieran encontrar los programas, las configuraciones y los resultados de cada uno de los experimentos.
- **Estrategia y accion:** tome las tareas del enunciado, las ordene por cada uno de los miembros (miembro responsable) y prepare el README general del proyecto y el plan del equipo a seguir. Ademas, separe las carpetas segun el tipo de archivo que ibamos a guardar en cada una de ellas.
- **Tiempo estimado:** 1 hora y 15 minutos.
- **Resultado y aprendizaje:** aprendi a organizar la evidencia antes de correr cada una de las pruebas correspondientes.
- **Evidencia:** commits `6b55736` y `ed405ae`. [Plan del equipo](plan_equipo.md).

### 4 de noviembre - Preparacion y primera prueba del entorno ARM

- **Necesidad:** tenia que comprobar que el entorno del grupo de trabajo podia ejecutar un programa ARM en el simulador gem5 de forma correcta.
- **Estrategia y accion:** prepare el Dockerfile respectivo y las configuraciones MESI y MOESI. Ademas, revise la informacion correspondiente para la compilacion y a su vez, ejecute un programa de hola mundo con la CPU en TimingSimple antes de probar la multiplicacion de matrices.
- **Tiempo estimado:** 2 horas y 30 minutos aproximadamente.
- **Resultado y aprendizaje:** obtuve una ejecucion de hola mundo en AArch64. Asimismo aprendi a hacer las 2 comprobaciones por separado: en primer lugar, consultar que simulador se compilo y en segundo lugar verificar que ese simulador puede ejecutar un programa puntual.
- **Evidencia:** commits `990b60e`, `d311677`, `db9957d` y `92504ed`. [Pruebas del entorno](../results/environment/).

### 7 de noviembre - Validacion del GEMM escalar

- **Necesidad:** antes de usar el GEMM para poder medir el rendimiento, necesitaba saber que obtenia un resultado que se puede indicar como correcto.
- **Estrategia y accion:** en primer lugar, repeti la prueba ARM del GEMM escalar con un tamano de N=16. Ademas, revise el registro de ejecucion y de la misma forma conserve los archivos que identifican el programa en cuestion y la configuracion que fue utilizada.
- **Tiempo estimado:** 1 hora.
- **Resultado y aprendizaje:** la prueba registro un mensaje de `CHECK=PASS` y 0 errores, como se esperaba. Ademas, aprendi a distinguir la validacion del calculo de la medicion de rendimiento, puesto que primero comprobe la respuesta del GEMM y continumanete despues pase a los tamanos oficiales requeridos.
- **Evidencia:** commit `1929071`. [Validacion de GEMM de Paulina](../results/validation/paulina_gemm_scalar_n16/).

### 8 de noviembre - Prueba piloto, correccion de un fallo y barrido de E2

- **Necesidad:** queria cambiar el ancho del nucleo y el tamano del ROB sin que otras diferencias de configuracion alteraran la comparacion a realizar
- **Estrategia y accion:** empece con un tamano de N=16, un ancho 2 y un ROB de 64 entradas, durante el barrido con el tamano de N=64 aparecio un fallo de `TimeBuffer`. Tuve que revisar el caso que fallo, y continuamente ajuste el `forwardComSize` a 256 y mantuve ese valor en todas las corridas oficiales para no alterar el analisis posterior. Finalmente complete las combinaciones por bloques.
- **Tiempo estimado:** 3 horas.
- **Resultado y aprendizaje:** quedaron 12 configuraciones para un tamano de N=64 y 12 configuraciones para un tamano de N=128. Aprendi que si se varia  un parametro para resolver un error, se debe aplicar ese mismo ajuste a las corridas que voy a comparar, para no generar un desfase en el analisis.
- **Evidencia:** commits `ce277d8`, `65e3411`, `f553f54` y `7ed804c`. [Configuraciones y resultados de E2](../results/e2/).

## Semana 2 - Del 9 al 15 de noviembre

### Del 9 al 15 de noviembre - Preparacion del avance grupal de E2

- **Necesidad:** necesitaba explicar al equipo de trabajo que habia probado en el experimento E2 y poder responder en que punto del analisis deja de mejorar el IPC.
- **Estrategia y accion:** revise las carpetas correspondientes a los resultados para un tamano de N=64 y de N=128. Asimismo para organizar la explicacion, separe las 2 preguntas del experimento, en primer lugar que cambia al aumentar el ancho con el mismo ROB y en segundo lugar que cambia al aumentar el ROB con el mismo ancho. Ademeas, utilices como ejemplo las corridas para un tamano de N=64 y un ancho 4 con un ROB de 32 y 64 entradas.
- **Tiempo estimado:** 45 minutos
- **Resultado y aprendizaje:** pude explicar por que habia 12 configuraciones por cada tamano de matriz, 4 anchos combinados con 3 capacidades del ROB. Tambien identifique, como extraer el dato del IPC de la misma region de interes en cada una de las corridas para de esta manera poder comparar los resultados bajo el mismo criterio.
- **Material revisado:** [N=64, ancho 4 y ROB 32](../results/e2/n64/ancho4_rob32/) y [N=64, ancho 4 y ROB 64](../results/e2/n64/ancho4_rob64/).

## Semana 3 - Del 16 al 22 de noviembre

### 21 de noviembre - Extraccion de las metricas de la ROI

- **Necesidad:** se necesitaba comparar las 24 configuraciones ejecutadas sin mezclar el tiempo de la multiplicacion con el trabajo posterior de verificacion.
- **Estrategia y accion:** reutilice el lector de estadisticas del proyecto que ya estaba publicado en el repositorio y prepare el resumen del experimento E2. Ademas, compare las filas del archivo CSV con el primer bloque de `stats.txt`, incluyendo ciclos, IPC y los fallos de prediccion.
- **Tiempo estimado:** 1 hora.
- **Resultado y aprendizaje:** obtuve una tabla con las 24 filas de datos. Ademas, aprendi que escoger el bloque correcto es igual de importante como el poder escoger el contador correcto. Asimismo, tambien deje indicado cuando el simulador gem5 no imprimio un contador de ROB lleno.
- **Evidencia:** commit `781aa69`. [CSV de rendimiento](../results/e2/summary/e2_metricas.csv).

### 21 de noviembre - Diferencia entre cola llena y ocupacion media

- **Necesidad:** se analizo que los eventos de cola llena me indican cuantas veces se registro un bloqueo, pero a su vez, todavia se necesitaba saber cuantas entradas de la IQ y del ROB correspondientes estaban ocupadas.
- **Estrategia y accion:** en primer lugar probe el medidor con un tamano de N=64, un ancho 4 y un ROB de 64 entradas. Ademas, comprobe que el archivo tenia las 1024 muestras correspondientes a la prueba mas el encabezado. Finalmente, despues aplique el mismo procedimiento a las otras configuraciones respectivas.
- **Tiempo estimado:** 1 hora y 30 minutos.
- **Resultado y aprendizaje:** uni las 1024 muestras por configuracion. Ademas, aprendi a precisar el alcance de la medida, puesto que la ocupacion obtenida llega a describir la ventana central observada. Ademas, el factor del IPC de la tabla de rendimiento corresponde a la ROI completa.
- **Evidencia:** commit `ff1073a`. [Muestras de las 24 configuraciones](../results/e2/ocupacion/).

### 21 de noviembre - Graficos, interpretacion y revision del informe

- **Necesidad:** en primer lugar tenia que responder en que condiciones en poder ampliar el nucleo dejaba de aportar una mejora apreciable y considerable y mostrarle de igual manera al grupo de trabajo como comprobarlo.
- **Estrategia y accion:** pude generar las figuras correspondientes, ademas compare las configuraciones que solo cambiaban de ancho y de las misma manera continue con contraste correspondiente de los resultados con los archivos CSV. Finalmente, documente el comando de reproduccion y continuamente revise el archivo de texto /docs para que el mismo incluyera tanto el IPC como la ocupacion.
- **Tiempo estimado:** 1 hora y 30 minutos.
- **Resultado y aprendizaje:** para un tamano de un N=128 y un ROB de 64 entradas, pasar de ancho 4 a 8 cambio el IPC de 1.033379 a 1.033452. Asimismo, en la ventana central el ROB tuvo una ocupacion media de un 94.16 % y un 94.65 % respectivamente para cada uno de ellas. Asimismo, aprendi a explicar por separado lo que observe y analisis. A su vez, estos datos sirven para proponer candidatos para el experimento E6, pero la eleccion final requiere medir su tiempo y costo puntualmente.
- **Evidencia:** commits `008240a`, `f2f6603`, `52284f1` y `6cd87a1`. [Graficos](../results/e2/figures/) y [aporte al informe](../report/e2.md).

## Semana 4 - Cierre pendiente


## Balance de las estrategias utilizadas

- **Pruebas pequenas:** se inicio con laa prueba del hola mundo y luego con el GEMM con un tamano de N=16 que me permitio comprobar primero el entorno y despues el programa. Asimismo, esta estrategia tambien me sirvio para probar una sola medicion de ocupacion antes de lanzar las otras 23 correspondientes.
- **Diagnostico a partir de un fallo:** revisar el caso de `TimeBuffer` me ayudo a generar de forma puntual una solucion sobre la configuracion y  mantenerla igual durante todo el barrido correspondiente.
- **Comparacion directa de datos:** contrastar el archivo `stats.txt`, los archivos CSV y las respectivas figuras me permitio detectar 2 diferencias importantes, en primer lugar un evento de cola llena no mide la ocupacion media y en segundo lugar una ventana de 1024 ciclos representa solo parte de la ROI correspondiente.
- **Revision del informe:** al comparar el resumen con las tablas respectivas, incorpore los diversos porcentajes de la IQ y del ROB que faltaban.

## Uso de IA y verificacion

Durante la preparacion del experimento E2 se utilizo las IA para poder orientar la lectura de los diversos contadores, asi como el organizar los pasos de comprobacion.
Por otra parte, las cifras del informe se verificaron con los archivos de las simulaciones del proyecto. Por ejemplo, los porcentajes obtenidos del IQ y del ROB para
un tamano de N=128, anchos 4 y 8 y de ROB de 64 entradas se contrastaron con el archivo [CSV de ocupacion](../results/e2/summary/e2_ocupacion.csv).
