# AC2. Ficha de vigilancia tecnológica

**Estudiante:** Sary Vargas [completar apellidos]
**Fecha:** [AAAA-MM-DD, semana 1]

## Tecnología 1. Arm Scalable Matrix Extension (SME y SME2)

**Qué es.** Una extensión de la arquitectura Armv9-A que agrega soporte para operaciones con matrices. Se apoya en SVE y SVE2: calcula el producto exterior de dos vectores y acumula el resultado en una matriz de registros (*tile*), con un modo de SVE en streaming [1], [2].

**Por qué importa.** Es el siguiente paso de la misma línea que estudiamos en E3: pasar de vectores a matrices. Su producto exterior reutiliza cada dato cargado para varios resultados, lo que apunta justo a la limitación que vimos en nuestro GEMM con SVE, donde la tasa de fallos de L1D subía con el VL.

**Cómo contribuye a mi aprendizaje.** Me obliga a distinguir qué ganancia viene de más datos por instrucción (VL) y cuál de reutilizar datos en registros. En E6 vi que aumentar el VL rindió más que aumentar núcleos; SME plantea otra vía para el mismo objetivo.

## Tecnología 2. RISC-V Vector Extension (RVV 1.0)

**Qué es.** La extensión vectorial abierta de RISC-V, ratificada a finales de 2021. Usa vectores de longitud variable y programación agnóstica a la longitud, igual que SVE, y existen implementaciones abiertas de procesadores vectoriales como Ara [3], [4].

**Por qué importa.** Permite comparar dos diseños vectoriales con la misma idea (longitud agnóstica) y una especificación pública. Como la usa hardware abierto, sus decisiones de diseño se pueden estudiar.

**Cómo contribuye a mi aprendizaje.** Me ayuda a entender qué parte de lo que medimos en E3 depende de SVE en particular y cuál es propia de cualquier ISA vectorial de longitud variable.

## Recurso de aprendizaje

**Learning gem5** (tutorial oficial de gem5, partes I a III) [5]. Lo uso para entender cómo se configura una simulación, cómo se organiza `config.ini` y cómo se definen las jerarquías de memoria. Se evalúa su utilidad en la bitácora (AC3) y en la reflexión final (AC4).

## Fuentes

[1] M. Weidmann, "Introducing the Scalable Matrix Extension for the Armv9-A Architecture," Arm Community, 14 de julio de 2021. https://developer.arm.com/community/arm-community-blogs/b/architectures-and-processors-blog/posts/scalable-matrix-extension-armv9-a-architecture
[2] Arm, *SME Programmer's Guide*, versión 1.0, documento 109246_0100_01_en, 2024.
[3] RISC-V International, *RISC-V Ratified Specifications Library* (extensión vectorial "V"). https://docs.riscv.org/reference/home/index.html
[4] M. Perotti et al., "A 'New Ara' for Vector Computing: An Open Source Highly Efficient RISC-V V 1.0 Vector Processor Design," arXiv:2210.08882.
[5] gem5 project, *Learning gem5*. https://www.gem5.org/documentation/learning_gem5/introduction/

## Uso de IA

Usé una IA para ubicar fuentes y resumir su contenido. Las referencias se comprobaron en las páginas originales y lo que afirmo de SME y RVV se limita a lo que dicen esas fuentes.
