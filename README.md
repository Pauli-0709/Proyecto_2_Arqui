#Arquitecturas paralelas para la multiplicación de matrices en gem5
Instituto Tecnológico de Costa Rica (TEC) · Arquitectura de Computadoras · Proyecto grupal

Este repositorio contiene los diversos programas, configuraciones, scripts y evidencias las cuales son necesarias para estudiar el rendimiento de la 
multiplicación de matrices densas (GEMM, C = A × B) utilizando la herramienta de  simulacion gem5, en modo System-call Emulation (SE) sobre 
arquitectura AArch64 implementada con ARMv8.

Asimismo, el presente trabajo analiza el paralelismo a nivel de instrucciones, el ancho superescalar y el búfer de reordenamiento (ROB), 
la vectorización Arm SVE, la ejecución multinúcleo y la coherencia de memoria. El objetivo final es recomendar una arquitectura respaldada 
por las diversas mediciones de GEMM y teniendo en cuenta una restricción de costo.

Estado del proyecto: inicializacion del mismo, se repartieron las funciones entre los diversos integrantes.

#Tabla de contenido
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


###1) Integrantes
El presente proyecto es desarrollado por los siguientes estudiantes:
- Paulina Camacho
- Sary Vargas
- Tomás Campos
- Steven Loaiza


###2) Objetivos y experimentos
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


###3) Distribución del trabajo
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

###4) Tecnologías y requisitos
- Ubuntu 24.04 nativo o en WSL2 (entorno de trabajo propuesto).
- gem5 v24.1.0.3 (versión fijada por las guías del equipo, no exigida por el profesor).
- GCC, SCons, Python 3, Bash, Git y GitHub.
- El compilador cruzado aarch64-linux-gnu-gcc y la biblioteca libm5.a de gem5.
- matplotlib para poder producir las diversas gráficas, qemu-user es opcional ya que es util para validar los diversos binarios ARM sin medir rendimiento.
- Espacio de disco y memoria suficientes para compilar gem5, asimismo la capacidad requerida depende del equipo y del nivel de paralelismo de la compilación respectiva.

###5) Estructura del repositorio

Proyecto_2_Arqui/
├── README.md                   # Presentación, autores y reproducción del presente proyecto
├── .gitignore                  # Ignora binarios y archivos temporales
├── docs/                       # Plan del equipo, acuerdos técnicos y bitácoras


###6) Instalacion paso a paso



###7) Compilacion y validacion


###8) Ejecucion de los experimentos


###9) Resultados y reproducibilidad



###10) Trabajo colaborativo y documentación



###11) Estado y entregables
