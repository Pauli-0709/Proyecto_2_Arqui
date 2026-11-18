# Validacion funcional del la programacion de GEMM paralelo

En primer lugar, `src/gemm_paralelo.c` va a recibir 2 argumentos, el tamano de la matriz y la cantidad de hilos. 
En segundo lugar, OpenMP reparte las filas completas de la matriz de salida. 
En tercer lugar, la region de interes incluye el calculo y la gestion del equipo de hilos.
En cuarto lugar, la inicializacion y la comprobacion contra una referencia que utiliza tipo double se ejecutan fuera de esa region.

Desde la raiz del repositorio, en Ubuntu, ejecutar:

```bash
bash scripts/arm_env.sh bash scripts/probar_gemm_paralelo.sh
```

Es importante mencionar que el script compila el programa en nativo y para AArch64 con enlace estatico. Asimismo, prueba N=16 con 1, 2, 4 y 8 hilos en 
nativo y en el simulador gem5. A su vez, en el simulador gem5 usa un nucleo O3 por hilo. De la misma manera, cada corrida exige `CHECK=PASS`, 0 errores y que el
numero de hilos que procesaron filas coincida con el solicitado. Tambien se comprueba que el simulador gem5 escriba 2 bloques completos de estadisticas.

Por otra parte, la prueba termina con un mensaje de `VALIDACION_PARALELA_OK N=16 CORRIDAS_GEM5=4`. Asimismo, la linea `SALIDA=` indica la carpeta de la corrida en
`results/validation/gemm_paralelo_n16.XXXXXX/`. Ademas es importante mencionar que los ejecutables se guardan en la carpeta `bin/`. Si una corrida falla, se debe revisar el `run.log`. 
Ademas, si OpenMP falla al iniciar los hilos en modo SE, el enunciado indica usar pthreads con enlace estatico.

[Evidencia de las cuatro corridas](../results/validation/gemm_paralelo_n16.BJhgEJ/).

Finalmente, las mediciones de rendimiento del experimento E4 usan un tamano de  N=64 y N=128 con 1, 2, 4 y 8 nucleos. Ademas, esta prueba funcional utiliza un 
tamano de N=16.
