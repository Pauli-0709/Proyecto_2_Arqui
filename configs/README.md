# Configuraciones de gem5

En esta carpeta contiene las diversas configuraciones de simulacion desarrolladas por el equipo de trabajo.

## Pendientes

- Configuracion para E1: TimingSimple, Minor y O3.
- Configuracion para E2: un nucleo O3, anchos de emisión 1, 2, 4 y 8, asi como los tamanos del ROB de 32, 64 y 192 entradas.

Los experimentos E1 y E2 utilizaran GEMM escalar con N=64 y N=128.

Es importante mencionar que cada configuracion debera documentar CPU, frecuencia, caches, memoria y paremetros modificados. Los diversos parametros
que no formen parte del barrido deberan mantenerse constantes y quedar registrados.

Finalmente es fundamental indicar que los resultados de las distintas simulaciones se guardan en la ruta de results/ y no en esta carpeta.
