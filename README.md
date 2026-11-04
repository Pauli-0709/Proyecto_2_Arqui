Arquitecturas paralelas para la multiplicación de matrices en gem5
Instituto Tecnológico de Costa Rica (TEC) · Arquitectura de Computadoras · Proyecto grupal

Este repositorio contiene los diversos programas, configuraciones, scripts y evidencias las cuales son necesarias para estudiar el rendimiento de la 
multiplicación de matrices densas (GEMM, C = A × B) utilizando la herramienta de  simulacion gem5, en modo System-call Emulation (SE) sobre 
arquitectura AArch64 implementada con ARMv8.

Asimismo, el presente trabajo analiza el paralelismo a nivel de instrucciones, el ancho superescalar y el búfer de reordenamiento (ROB), 
la vectorización Arm SVE, la ejecución multinúcleo y la coherencia de memoria. El objetivo final es recomendar una arquitectura respaldada 
por las diversas mediciones de GEMM y teniendo en cuenta una restricción de costo.

