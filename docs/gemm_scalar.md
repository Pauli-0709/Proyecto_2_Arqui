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
