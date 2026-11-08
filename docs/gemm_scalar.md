# GEMM escalar

## Objetivo

EL objetivo principal es el de poder implementar la operacion de matrices dada por C = A * B, utilizando matrices de precision simple para los 
experimentos E1 y E2.

## Implementacion

- Las matrices son almacenadas por filas en arreglos continuos
- La multiplicacion escalar se efectuo siguiendo el orden de bucles i-j-k
- Los datos deterministas son iguales para todas las configuraciones
- La acumulacion del kernel se efectuo utilizando datos tipo float
- La verificacion de todos los elementos vs una referencia de tipo double
- La referencia calculada se efectuo siguiendo el orden de bucles j-k-i

## Validacion nativa

Dentro del Docker:

```bash
cd /work
bash scripts/test_gemm_native.sh
```

Asimismo, el script compila y prueba los casos con un tamano de matriz de N=16, N=64 y N=128. A su vez, el mismo tambien comprueba que caso 
critico N=0 sea rechazado de forma correcta.

De la misma forma, es importante mencionar que las opciones de compilacion desactivan la autovectorizacio y la fusion de multiplicacion y suma.

## Evidencias

Los registros se guardan en la ruta:

results/validation/gemm_scalar_native/

Ademas, tambien se va a conservar la version del compilador y el hash del codigo probado.

Finalmente, es importante mencionar que los ejecutables se generan en la carpeta bin/ y los mismos no se incluyen en Git.

## Validacion ARM con gem5

Dentro del Docker:

```bash
cd /work
bash scripts/test_gemm_arm.sh
```

En primer lugar, este script en particular genera un ejecutable estatico AArch64 con USE_GEM5. Continuamente ejecuta N=16 sobre un nucleo ArmTimingSimpleCPU.

En segundo lugar, el resultado esperado es CHECK=PASS con cero errores.

En tercer y ultimo lugar, las evidencias se guardan en la ruta:

results/validation/gemm_scalar_n16/

## Region de interes

La secuencia del programa es el siguiente:

1. Inicializar matrices.
2. Ejecutar m5_reset_stats(0, 0).
3. Ejecutar gemm_scalar.
4. Ejecutar m5_dump_stats(0, 0).
5. Verificar el resultado.
6. Liberar memoria.

De la misma manera, la inicializacion y la referencia quedan fuera del bloque de estadisticas de la multiplicacion.

Es importante mencionar que con este programa y el script de validacion, sin volcados adicionales, el primer bloque de stats.txt corresponde 
al volcado de la ROI. De la misma manera, el volcado final puede incluir la verificacion posterior.

Finalmente, el reinicio de las estadisticas no vacia las memorias caches.

## Uso por la persona A - Paulina Camacho (Distribucion de tareas)

En primer lugar, se debe actualizar la copia del repositorio y ejecutar los scripts dentro del contenedor o docker.

En segundo lugar, el ejecutable que se ubica en la ruta bin/gemm_scalar acepta N como unico argumento. Es importante mencionar que para E2 
(experimento 2) se debe utilizar un tamano de matriz de N=64 y N=128.

En tercer lugar, la prueba ARM incluida es una validacion funcional con un tamano de matriz de N=16. Asimismo, no representa los resultados 
del barrido O3 de E2.

## Comparabilidad

Se debe mantener el mismo codigo, datos y opciones de compilacion en todas las configuraciones comparadas de E1 y E2.
