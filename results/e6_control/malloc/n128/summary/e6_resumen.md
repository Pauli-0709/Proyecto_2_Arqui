# E6. Resultados N=128, presupuesto 32

- Menor tiempo: **c02_1n_w2_vl1024** (0.5336 ms, costo 9).
- Mejor rendimiento/costo: **c01_1n_w2_vl512** (0.2799, costo 5).
- Frente de Pareto: c01_1n_w2_vl512, c02_1n_w2_vl1024.

| Config | Nucleos | Ancho | VL | Costo | ROI (ms) | Rend/costo | Speedup vs base | L1D fallos (%) | Presupuesto |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :---: |
| c02_1n_w2_vl1024 | 1 | 2 | 1024 | 9 | 0.5336 | 0.2082 | 1.34 | 59.6 | si |
| c01_1n_w2_vl512 | 1 | 2 | 512 | 5 | 0.7144 | 0.2799 | 1.00 | 53.0 | si |
