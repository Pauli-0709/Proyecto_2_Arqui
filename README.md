# Arquitecturas paralelas para la multiplicación de matrices en gem5
Instituto Tecnológico de Costa Rica (TEC) · Arquitectura de Computadoras · Proyecto grupal #2

Este repositorio contiene los diversos programas, configuraciones, scripts y evidencias las cuales son necesarias para estudiar el rendimiento de la 
multiplicación de matrices densas (GEMM, C = A × B) utilizando la herramienta de  simulacion gem5, en modo System-call Emulation (SE) sobre 
arquitectura AArch64 implementada con ARMv8.

Asimismo, el presente trabajo analiza el paralelismo a nivel de instrucciones, el ancho superescalar y el búfer de reordenamiento (ROB), 
la vectorización Arm SVE, la ejecución multinúcleo y la coherencia de memoria. El objetivo final es recomendar una arquitectura respaldada 
por las diversas mediciones de GEMM y teniendo en cuenta una restricción de costo.

Estado del proyecto: inicializacion del mismo, se repartieron las funciones entre los diversos integrantes.

Actualizacion del entorno (7 de noviembre de 2026): imagen del Docker env2 publicada y se realizaron las diversas pruebas ARM que fueron completadas
con exito. Las seccion 6 y 7 indican como descargarla y usurla, la seccion 11 resume el avance.

# Tabla de contenido
1. Integrantes
2. Objetivos y experimentos
3. Distribución del trabajo
4. Tecnologías y requisitos
5. Estructura del repositorio
6. Instalación paso a paso
7. Compilación y validación
8. Ejecución de los experimentos
9. Resultados y reproducibilidad
10. Trabajo colaborativo y documentación
11. Estado y entregables


### 1) Integrantes
El presente proyecto es desarrollado por los siguientes estudiantes:
- Paulina Camacho
- Sary Vargas
- Tomás Campos
- Steven Loaiza


### 2) Objetivos y experimentos
Se utilizan programas disenados utilizando el lenguage de programacion C, matrices float de tamaño N × N y compilación estática AArch64. 
De la misma manera, los tamaños oficiales principales son N = 64 y N = 128. Por otra parte, las mediciones se realizan sobre la región de 
interés (ROI), marcada mediante m5_reset_stats() y m5_dump_stats().


| Experimento | Qué se estudia | Variantes y métricas principales | Liderazgo |
| --- | --- | --- | --- |
| **E1: línea base** | Procesadores TimingSimple, Minor y O3 | 1 núcleo; ciclos, IPC, CPI y fallos de caché L1D/L2 | Equipo completo |
| **E2: superescalar** | Paralelismo a nivel de instrucciones | Anchos 1, 2, 4 y 8; ROB 32, 64 y 192; IPC, ocupación IQ/ROB y predicción | Paulina Camacho |
| **E3: vectorial** | Extensiones SVE | Escalar frente a SVE; VL de 128, 256, 512 y 1024 bits; ciclos, instrucciones y *speedup* | Steven Loaiza |
| **E4: multinúcleo** | Memoria compartida y escalabilidad | 1, 2, 4 y 8 núcleos O3; *speedup*, eficiencia y fallos L2 | Sary Vargas |
| **E5: coherencia** | MESI, MOESI y falso compartido | `MESI_Two_Level` y `MOESI_CMP_directory`; invalidaciones, mensajes y latencias | Tomas Campos |
| **E6: integración** | Selección de arquitectura | Al menos 6 configuraciones con costo ≤ 32 y GEMM con `N = 128` | Equipo completo |


Modelo de costo del enunciado:
Costo = # de núcleos × (ancho_de_emisión / 2 + VL(longitud_vectorial)_en_bits / 128)
Costo máximo = 32 unidades

De la misma manera, la elección final debe considerar resultados medidos, costo y rendimiento/costo; no basta con solamente  seleccionar la 
configuración de más recursos.


### 3) Distribución del trabajo
Esta sección describe qué aporta cada rol/encargado al repositorio, no es solamente una lista de instrucciones para ejecutar manualmente. De la misma
es importante indicar que las guías detalladas permanecen en docs/ y en los documentos de apoyo del grupo.


| Rol | Responsabilidad técnica | Archivos y evidencias principales |
| --- | --- | --- |
| **Paulina Camacho** | Organizar Git/GitHub, preparar gem5 ARM, establecer el entorno común y liderar **E2**. Participar en E1 y E6. |  |
| **Steven Loaiza** | Desarrollar/validar los benchmarks, automatizar simulaciones y liderar **E3 (SVE)**. Facilitar programas a C y D; participar en E1 y E6. |  |
| **Sary Vargas** | Liderar **E4**, evaluar 1/2/4/8 núcleos, calcular eficiencia y estimar la fracción serial con Amdahl. Coordinar el avance de resultados E1–E3. | |
| **Tomas Campos** | Liderar **E5**, comparar protocolos de coherencia y cuantificar el falso compartido, con y sin relleno. |  |


Actividades compartidas: E1, E6, revisión de resultados, informe IEEE, presentación/video, coevaluación y actividades individuales de 
aprendizaje continuo AC1–AC4. Todos deben poder explicar los resultados del equipo.

### 4) Tecnologías y requisitos
- Ubuntu nativo o en WSL2 (entorno de trabajo propuesto).
- gem5
- GCC, SCons, Python 3, Bash, Git y GitHub.
- El compilador cruzado aarch64-linux-gnu-gcc y la biblioteca libm5.a de gem5.
- matplotlib para poder producir las diversas gráficas, qemu-user es opcional ya que es util para validar los diversos binarios ARM sin medir rendimiento.
- Espacio de disco y memoria suficientes para compilar gem5, asimismo la capacidad requerida depende del equipo y del nivel de paralelismo de la compilación respectiva.

#### Entorno compartido del Docker
El entorno está disponible como una imagen Docker ya compilada. Asimismo, para usarlo, cada integrante necesita Docker funcionando y la 
herramienta de Git, de la misma manera no necesita instalar gem5, SCons ni el compilador AArch64 por separado en Ubuntu.

| Elemento | Configuración |
| --- | --- |
| Imagen publicada | `ghcr.io/pauli-0709/proyecto2-gem5:24.1.0.1-env2` |
| Plataforma de la imagen | `linux/amd64` |
| Sistema base | Ubuntu 22.04 |
| Versión gem5 | 24.1.0.1 |
| Commit gem5 | `c9625ce9cc5b5a90a38327de5ac0e1870974af5e` |
| Protocolos compilados | `MESI_Two_Level` y `MOESI_CMP_directory` |
| Compilador incluido | `aarch64-linux-gnu-gcc` |

De la misma manera, es importante indicar que la imagen corre en un equipo x86-64 y gem5 simula ARM. Por ende se requiere espacio para las capas 
descomprimidas y los resultados. Asimismo además de memoria RAM suficiente para las diversas simulaciones. A su vez, la descarga evita repetir 
la compilación del simulador en forma independiente.

### 5) Estructura del repositorio

```text
Proyecto_2_Arqui/
├── README.md
├── docker/       # Entorno y compilación de gem5
├── docs/         # Plan del equipo y documentacion
├── src/          # Programas de los distintos experimentos
├── configs/      # Configuraciones de las diversas simulaciones
├── scripts/      # Validacion, ejecucion y analisis
├── tests/        # Programas de prueba del entorno
├── results/      # Evidencias, estadisticas, CSV y graficos del proyecto
└── report/       # Informe tecnico y materiales de exposicion
```

Nota: las carpetas configs/ y report/ contienen la documentacion inicial. Sus diversas implementaciones y entregables siguen pendientes.

Archivos del entorno Docker y sus pruebas:

| Ruta | Función |
| --- | --- |
| `docker/Dockerfile` | Receta única: instala dependencias, luego compila MESI/MOESI y finalmente se agrega las rutas `build/` del enunciado del proyecto. |
| `docker/ARM_MESI.defconfig` | Configuración ARM con MESI. |
| `docker/ARM_MOESI.defconfig` | Configuración ARM con MOESI. |
| `scripts/arm_env.sh` | Abre el contenedor y luego se conecta el repositorio local con `/work`. |
| `tests/environment/hola.c` | Programa de prueba que lo que realiza es una impresion de `HOLA_ARM_OK`. |
| `bin/` | Ejecutables locales generados los cuales no estan destinados a Git. |
| `results/environment/` | Configuraciones y estadísticas de las pruebas. |

### 6) Instalacion paso a paso

#### 6.1. Preparar Ubuntu

Es importante mencionar que los comandos de esta sección se ejecutan en la terminal de Ubuntu, fuera del contenedor.

En primer lugar, se debe comprobar que el Docker esté correctamente instalado y que el mismo siga funcionando:

```bash
sudo docker version
sudo docker run --rm hello-world
```

Continuamente si el Docker no está instalado, seguir la guía oficial:
https://docs.docker.com/engine/install/ubuntu/

Es importante mencionar que si se utiliza Ubuntu en WSL2 con Docker Desktop, habilitar la integración con esa distribución.

En segundo lugar, instalar Git si hace falta:

```bash
sudo apt update
sudo apt install -y git
```

#### 6.2. Clonar el repositorio

En primer lugar, si todavía no se tiene el proyecto:

```bash
cd ~
git clone https://github.com/Pauli-0709/Proyecto_2_Arqui.git
cd Proyecto_2_Arqui
```

Importante si el repositorio ya está clonado, entrar en su carpeta existente.

Finalmente, lsos siguientes pasos se realizan desde la raíz del repositorio, donde esta alogado el archivo README.md y las carpetas docker, 
scripts y tests.

#### 6.3. Descargar la imagen

En primer lugar, la imagen contiene gem5 ya compilado para ARM con los protocolos del proyecto los cuales son el  MESI y el MOESI. Asimismo para 
descargarla, ejecutar el siguiente comando:

```bash
sudo docker pull --platform linux/amd64 \
  ghcr.io/pauli-0709/proyecto2-gem5:24.1.0.1-env2
```

Esperar a que termine la descarga y vuelva a aparecer el indicador de la terminal.

#### 6.4. Entrar al contenedor

```bash
bash scripts/arm_env.sh
```

Esta linea de comando tiene un script que abre una terminal dentro del contenedor utilizando la imagen env2. De la misma manera, el repositorio de Ubuntu se 
conecta con la carpeta `/work`.

Por ejemplo, un archivo guardado dentro del contenedor en `/work/results/` también aparece en la carpeta `results/` del repositorio de Ubuntu.

IMPORTANTE: A partir de este punto, los comandos de la sección 7 se ejecutan dentro del contenedor. NO ES necesario volver a compilar gem5.

### 7) Compilacion y validacion

#### 7.1. Comprobar los simuladores

En primer lugar, dentro del contenedor, entrar en la carpeta de gem5:

```bash
cd /opt/gem5
```

En segundo lugar, comprobar los dos ejecutables:

```bash
build/ARM_MESI/gem5.opt --build-info
build/ARM_MOESI/gem5.opt --build-info
```

Ambos deben mostrar gem5 24.1.0.1. El primero debe indicar el protocolo MESI_Two_Level y el segundo MOESI_CMP_directory.

#### 7.2. Compilar el programa de prueba

Es importante mencionar que el ejemplo del profesor requiere un archivo hola.c y lo compila para ARM. En este repositorio se utiliza 
`tests/environment/hola.c`, el cual tiene como objetivo imprimir el mensaje `HOLA_ARM_OK`.

En primer lugar, compilarlo dentro del contenedor:

```bash
mkdir -p /work/bin

aarch64-linux-gnu-gcc -O2 -static \
  /work/tests/environment/hola.c \
  -o /work/bin/hola_arm
```

En segundo lugar, comprobar el archivo generado:

```bash
file /work/bin/hola_arm
```

Finalmente se debe identificarse como un ejecutable AArch64 con enlace estático. Este programa se ejecutará mediante gem5.

#### 7.3. Ejecutar la simulación

En primer lugar, crear una carpeta de resultados para la prueba:

```bash
cd /opt/gem5

salida="/work/results/environment/hola_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$salida"
```

En segundo lugar, ejecutar:

```bash
build/ARM_MESI/gem5.opt -d "$salida" \
  configs/deprecated/example/se.py \
  --cpu-type=ArmTimingSimpleCPU \
  --caches --l2cache --mem-size=512MiB \
  -c /work/bin/hola_arm
```

Explicacion tecnica del anterior comandoo:

- `build/ARM_MESI/gem5.opt` inicia el simulador.
- `-d "$salida"` selecciona la carpeta de resultados.
- `se.py` configura la simulación en modo SE.
- `-c /work/bin/hola_arm` selecciona el programa compilado.

Es importante mencionar que la opción `-d` debe colocarse antes de `se.py`. A su vez, se guardaran los resultados en `/work` porque es la 
carpeta del repositorio y la misma permite conservarlos al cerrar el contenedor.

#### 7.4. Comprobar el resultado

Inmediatamente después de la simulación, ejecutar:

```bash
echo "Código de salida: $?"
test -s "$salida/stats.txt" && echo "Estadísticas generadas"
```

La prueba debe imprimir `HOLA_ARM_OK`, terminar normalmente, y poder mostrar el código de salida `0` y generar un archivo `stats.txt` no vacío.

Para consultar las CPU disponibles:

```bash
build/ARM_MESI/gem5.opt \
  -d /work/results/environment/lista_cpu \
  configs/deprecated/example/se.py --list-cpu-types
```

#### 7.5. Salir del contenedor

```bash
exit
```

Este comando te devuelve al entorno de Ubuntu y continuamente se pueden consultar los resultados:

```bash
ls results/environment
```

La imagen y los resultados permanecen guardados. Para volver a entrar en otro momento, ejecutar `bash scripts/arm_env.sh` desde el repositorio.

### 8) Ejecucion de los experimentos

Es importante mencionar que los comandos del simulador se ejecutan dentro del contenedor, desde `/opt/gem5`.

| Ruta | Función |
| --- | --- |
| `build/ARM_MESI/gem5.opt` | Simulador compilado con MESI. |
| `build/ARM_MOESI/gem5.opt` | Simulador compilado con MOESI. |
| `configs/deprecated/example/se.py` | Configuración SE del ejemplo del profesor. |
| `/work/bin/` | Programas compilados del proyecto. |
| `/work/results/` | Resultados de las simulaciones. |

De la misma manera, las rutas `build/ARM_MESI` y `build/ARM_MOESI` son enlaces a los ejecutables originales de `out/`.

Es importante indicar que para adaptar los ejemplos del HTML, utilizar  `-c` con la ubicación del programa compilado y `-d /work/results/...` 
para obtener los diversos resultados.

Consecuentemente para utilizar Ruby se debe agregar `--ruby`. A su vez, la prueba de la sección 7 utiliza cachés clásicas y no valida la 
coherencia multinúcleo.

Finalmente, los comandos de los experimentos E1–E6 se agregarán conforme se completen y validen sus programas.

### 9) Resultados y reproducibilidad

Guardar cada corrida en una carpeta distinta y conservar los archivos stats.txt, config.ini y config.json, junto con el comando utilizado.

Posteriormente, el entorno utiliza la imagen 24.1.0.1-env2 y gem5 24.1.0.1.

Finalmente, para los experimentos GEMM, extraer las métricas únicamente de la región de interés delimitada por m5_reset_stats() y m5_dump_stats().
Ademas, la prueba ejecutada del hola mundo solamente va a compruebar el funcionamiento del entorno.

### 10) Trabajo colaborativo y documentación

Los programas y scripts se editan en el repositorio de Ubuntu. Asimismo, los cambios deben aparecer dentro del contenedor en `/work`.

De la misma manera, cada integrante debe descargar la imagen publicada y ejecutar la prueba inicial antes de trabajar en los experimentos, para
verificar el funcionamiento correcto del docker.

#### Construir la imagen desde el Dockerfile

Es importante mencionar que este paso solo se necesita para reconstruir el entorno. No es necesario para utilizar la imagen descargada.

En primer lugar, desde Ubuntu, en la raíz del repositorio, ejecutar los siguientes comandos:

```bash
sudo docker build --progress=plain --build-arg JOBS=1 \
  -f docker/Dockerfile \
  -t proyecto2-gem5:rebuild \
  docker
```

Es importante mencionar que el Dockerfile instala las herramientas, compila gem5 para MESI y MOESI y agrega las rutas build/ utilizadas en el 
enunciado.

Asimismo, JOBS indica cuántos trabajos de compilación se ejecutan simultáneamente. La construcción puede tardar varias horas si no hay caché. De la 
misma manera, la imagen reconstruida queda guardada como `proyecto2-gem5:rebuild` y a su vez el lanzador continúa utilizando env2.

En segundo lugar, para comprobar los ejecutables de la imagen reconstruida:

```bash
sudo docker run --rm proyecto2-gem5:rebuild \
  /opt/gem5/build/ARM_MESI/gem5.opt --build-info

sudo docker run --rm proyecto2-gem5:rebuild \
  /opt/gem5/build/ARM_MOESI/gem5.opt --build-info
```

Finalmente, antes de publicar una nueva versión, se debe repetir también la prueba ARM utilizando esa imagen en particular.

#### Seguimiento del equipo

En el [tablero de tareas](docs/plan_equipo.md) se registra los diversas personas responsables de las mismas, teniendo en cuenta los estados, 
fechas objetivo, dependencias y evidencias.

Asimismo, se revisa dos veces por semana. A su vez, cada tarea se cierra cuando su evidencia esta publicada en el repositorio oficial y revisada por el grupo de trabajo.

Por otra parte, los commits representan avances concretos, como lo son la organizacion, la implementacion, la validacion, los resultados o 
documentacion de los mismo. Antes de subir cambios se debe revisar la lista de los archivos incluidos en el commit.


### 11) Estado y entregables

- Imagen Docker env2 publicada.
- Ejecutables MESI y MOESI comprobados mediante --build-info.
- Listado de CPU obtenido correctamente.
- Prueba inicial ARM completada con HOLA_ARM_OK, código cero y estadísticas.
- GEMM escalar validado de forma nativa para N=16, N=64 y N=128.
- GEMM escalar validado en gem5 ARM para N=16, con CHECK=PASS.
- Validacion ARM repetida por Paulina Camacho y publicada en results/validation/.
- Pendientes: los otros benchmarks y los experimentos E1 hasta el E6.
- E2 pendiente: configuracion O3, 24 corridas, CSV, analisis y graficos.
