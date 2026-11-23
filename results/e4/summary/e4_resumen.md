## Escalado (primer bloque de stats = ROI)

| N | Núcleos | Tiempo (s) | Speedup | Eficiencia | f serial | IPC agregado |
|---|---|---|---|---|---|---|
| 64 | 1 | 8.210e-04 | 1.000 | 1.000 | nan | 1.14 |
| 64 | 2 | 4.210e-04 | 1.950 | 0.975 | 0.0256 | 2.23 |
| 64 | 4 | 2.190e-04 | 3.749 | 0.937 | 0.0223 | 4.33 |
| 64 | 8 | 1.220e-04 | 6.730 | 0.841 | 0.0270 | 8.18 |
| 128 | 1 | 6.429e-03 | 1.000 | 1.000 | nan | 1.15 |
| 128 | 2 | 3.256e-03 | 1.975 | 0.987 | 0.0129 | 2.28 |
| 128 | 4 | 2.307e-03 | 2.787 | 0.697 | 0.1451 | 3.23 |
| 128 | 8 | 1.996e-03 | 3.221 | 0.403 | 0.2120 | 3.81 |

## Memoria y balance

| N | Núcleos | Fallo L1D | Accesos L2 | Fallos L2 | Fallo L2 | Desbalance de ciclos |
|---|---|---|---|---|---|---|
| 64 | 1 | 2.58% | 7357 | 70 | 0.95% | 0.00% |
| 64 | 2 | 2.65% | 5876 | 258 | 4.39% | 2.10% |
| 64 | 4 | 2.84% | 5218 | 349 | 6.69% | 5.62% |
| 64 | 8 | 3.03% | 5936 | 529 | 8.91% | 14.44% |
| 128 | 1 | 39.84% | 1638413 | 88 | 0.01% | 0.00% |
| 128 | 2 | 40.10% | 1208798 | 402 | 0.03% | 0.27% |
| 128 | 4 | 39.91% | 1212211 | 525 | 0.04% | 0.54% |
| 128 | 8 | 39.14% | 1168442 | 846 | 0.07% | 0.92% |

## Ajuste de Amdahl (mínimos cuadrados sobre 1/S)

| N | f ajustada | Speedup máx. teórico | Desviación máx. del modelo |
|---|---|---|---|
| 64 | 0.0251 | 39.8x | 1.12% |
| 128 | 0.1566 | 6.4x | 18.49% |

Una desviación grande o una `f serial` por punto que cambia con los núcleos indica que una fracción serial constante no describe los datos (hay otro factor, p. ej. memoria).

## Parámetros de la simulación

```
tamanos=64 128
nucleos=1 2 4 8
ancho=2
etapas=fetchWidth decodeWidth renameWidth dispatchWidth issueWidth wbWidth commitWidth
rob=192
iq=64
forwardComSize=256
mem=512MiB
cpu=ArmO3CPU
cache=clasica L1 32KiB/2v L2 256KiB/8v linea 64B DDR3_1600_8x8 2GHz
```
