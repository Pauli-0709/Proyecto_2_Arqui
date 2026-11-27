# Informe y presentacion de los resultados

Esta carpeta tiene como fin tener el informe técnico y los diversos materiales de exposicion si asi se requiere.

## Entregables previstos

1) Informe tecnico en formato IEEE, de maximo ocho paginas.
2) Analisis de E1 a E6 y referencias a sus las respectivas evidencias.
3) Enlace del video de conclusiones.

Asimismo, cada integrante aportara el analisis de su experimento. A su vez, el informe, la revision final y el video son responsabilidad general
del equipo.

Por otra parte, los datos crudos, CSV y los graficos se conservaran en la ruta de results/. De forma similar, los scripts para generarlos se 
conservaran en la siguiente ruta: scripts/.

## Aportes al informe

- [E1. Linea base de un nucleo](e1.md). El texto incluye la comparacion de los 3 modelos/configuraciones, sus respectivas evidencias y el comando de reproduccion
del experimento.

- [E2. Arquitectura superescalar](e2.md). El texto incluye el IPC, la ocupacion del IQ y del ROB, ademas de los fallos de prediccion y el aporte de
E2.

- [E3. Multiplicacion de matrices con SVE](e3.md). Este archivo incluyen la comparacion con el GEMM escalar, ademas de los resultados principales y
el enlace al grafico.

- [E4. Escalabilidad de GEMM en un multiprocesador](e4.md). Este archivo incluye los resultados con 1, 2, 4 y 8 nucleos, ademas el analisis de eficiencia y
los diversos fallos de L2, su estimacion correspondiente de la fraccion serial con Amdahl y la comparacion realizada con la variante `i-k-j`.
- [E6. Integración y exploración con presupuesto de costo](https://github.com/Pauli-0709/Proyecto_2_Arqui/blob/main/report/e6.md). Este archivo incluye las 12 configuraciones evaluadas con costo máximo de 32 (N = 128), la mejor configuración por tiempo y por rendimiento/costo, el frente de Pareto, el análisis de sensibilidad (N = 256 y presupuesto de 16), el control de alineamiento de memoria y la propuesta final.


El informe grupal en formato IEEE sigue pendiente de integracion.
