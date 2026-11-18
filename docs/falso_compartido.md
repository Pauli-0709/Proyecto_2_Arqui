# Validacion del SRC de falso compartido

En primer lugar, el programa `src/falso_compartido.c` recibe `HILOS MODO [ITERACIONES]`. A su vez, acepta de 2 a 8 hilos y usa 100 000 incrementos por hilo 
si se omite el argumento "ITERACIONES". Ademas, cada hilo incrementa su propio contador de 8 bytes.

- `sin_relleno` coloca los contadores en la misma linea de 64 bytes
- `con_relleno` separa los contadores para que cada uno tenga su linea

Asimismo, la region de interes comienza con el equipo de hilos listo e incluye los incrementos y las barreras que delimitan el trabajo. Ademas, la revision
de los valores finales se hace fuera de esa region.

Por otra parte en el simulador gem5, el programa escribe el resultado y termina con `m5_exit` o `m5_fail`. Esto se efectup asi para evitar el cierre del grupo 
de hilos mediante `exit_group`, que el mismo llego a producir un aborto en TimingSimpleCPU con Ruby.

Por otra parte, desde la raiz del repo en Ubuntu, ejecutar:

```bash
bash scripts/arm_env.sh bash scripts/probar_falso_compartido.sh
```

Esta prueba usa 2 hilos, 2 nucleos y 1000 incrementos por hilo. Ademas, verifica ambos modos en nativo y en el simulador gem5 con Ruby, una vez por cada modo:
una con MESI_Two_Level y otra con MOESI_CMP_directory.

El resultado esperado es `VALIDACION_FALSO_COMPARTIDO_OK CORRIDAS_GEM5=4`. Ademas, la linea `SALIDA=` indica donde quedan `run.log` y `stats.txt` para
cada combinacion de protocolo y modo. De la misma manera, el primer bloque de estadisticas corresponde a la region de interes.

Finalmente, el paso 11 del enunciado completa E5 con el barrido de nucleos y protocolos, las corridas de GEMM paralelo y el analisis de invalidaciones, 
mensajes y latencia de fallos.
