## Escalado (primer bloque de stats = ROI)

| N | Núcleos | Tiempo (s) | Speedup | Eficiencia | f serial | IPC agregado |
|---|---|---|---|---|---|---|
| 64 | 1 | 8.100e-04 | 1.000 | 1.000 | nan | 1.31 |
| 64 | 2 | 4.150e-04 | 1.952 | 0.976 | 0.0247 | 2.57 |
| 64 | 4 | 2.160e-04 | 3.750 | 0.938 | 0.0222 | 4.98 |
| 64 | 8 | 1.210e-04 | 6.694 | 0.837 | 0.0279 | 9.35 |
| 128 | 1 | 6.464e-03 | 1.000 | 1.000 | nan | 1.31 |
| 128 | 2 | 3.243e-03 | 1.993 | 0.997 | 0.0034 | 2.60 |
| 128 | 4 | 1.631e-03 | 3.963 | 0.991 | 0.0031 | 5.18 |
| 128 | 8 | 8.310e-04 | 7.779 | 0.972 | 0.0041 | 10.25 |

## Memoria y balance

| N | Núcleos | Fallo L1D | Accesos L2 | Fallos L2 | Fallo L2 | Desbalance de ciclos |
|---|---|---|---|---|---|---|
| 64 | 1 | 0.39% | 1002 | 72 | 7.19% | 0.00% |
| 64 | 2 | 0.53% | 1131 | 260 | 22.99% | 2.17% |
| 64 | 4 | 0.76% | 1269 | 351 | 27.66% | 5.72% |
| 64 | 8 | 1.15% | 1713 | 542 | 31.64% | 14.79% |
| 128 | 1 | 6.60% | 104557 | 85 | 0.08% | 0.00% |
| 128 | 2 | 5.96% | 55020 | 367 | 0.67% | 0.27% |
| 128 | 4 | 5.72% | 32020 | 543 | 1.70% | 0.77% |
| 128 | 8 | 5.51% | 21746 | 1104 | 5.08% | 2.20% |

## Ajuste de Amdahl (mínimos cuadrados sobre 1/S)

| N | f ajustada | Speedup máx. teórico | Desviación máx. del modelo |
|---|---|---|---|
| 64 | 0.0254 | 39.4x | 1.49% |
| 128 | 0.0036 | 276.6x | 0.31% |

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
