# Instrucciones que va a tener el  docker
# Sistema base del conteneder
#--------------------------------------------------------------------------------------------------------------------------------------------------------

# Esta version se eligio para el entorno.
# NOTA: no es un requisito explicito del enunciado del profesor.
FROM ubuntu:22.04

# Evita las posibles preguntas interactivas durante la instalacion de los diversos paquetes.
ARG DEBIAN_FRONTEND=noninteractive

# Instala las herramientas para compilar el simulador gem5 y los programas necesarios de ARM.
# Asimismo se debe incluir los compiladores, el Python, el SCons y las bibliotecas necesarias.
# De la misma manera, el compilador aarch64 va a permitir el poder generar los ejecutables ARM desde x86.
# Finalmente, se eliminaran las listas de los diversos paquetes para reducir la imagen.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ca-certificates m4 scons python3-dev python3-pip \
    python3-six python3-pydot python3-pil python3-numpy python3-pandas \
    python3-matplotlib zlib1g-dev libprotobuf-dev protobuf-compiler \
    libprotoc-dev libgoogle-perftools-dev libboost-all-dev libhdf5-dev \
    libpng-dev libelf-dev pkg-config gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu binutils-aarch64-linux-gnu libc6-dev-arm64-cross \
    file && rm -rf /var/lib/apt/lists/*


# Esta seccion va a descargar la version elegida de gem5 en /opt/gem5.
# Continamente debe comprobar el commit para detectar si el codigo descargado no coincide con el esperado y poder asi mantener un entorno reproducible.
RUN git clone --depth 1 --branch v24.1.0.1 https://github.com/gem5/gem5.git /opt/gem5 \
    && test "$(git -C /opt/gem5 rev-parse HEAD)" = c9625ce9cc5b5a90a38327de5ac0e1870974af5e


# Esta linea va a copiar desde la carpeta del docker del proyecto las distintas configuraciones que se van a seleccionar en ARM y los protocolos MESI y MOESI
COPY ARM_MESI.defconfig ARM_MOESI.defconfig /opt/defconfigs/

# Esta linea va a definir la cantidad de trabajos simultaneos de compilacion.
# Asimismo se puede cambiar al construir con --build-arg JOBS=1.
ARG JOBS=2


# Esta linea contiene los siguientes comandos se deben ejecutar desde el codigo de gem5.
WORKDIR /opt/gem5

# Esta seccion va a preparar la configuracion necesaria de MESI y continuamente compila el simulador respectivo.
# NOTA: -j controla el paralelismo de compilacion.
# --limit-ld-memory-usage va ayudar a limitar el consumo del enlazador.
RUN scons --ignore-style defconfig out/ARM_MESI /opt/defconfigs/ARM_MESI.defconfig \
    && scons --ignore-style --limit-ld-memory-usage out/ARM_MESI/gem5.opt -j${JOBS}

# Esta seccion va a preparar la configuracion necesaria de MOESI y continuamente compila un segundo simulador.
# De la misma manera, se usan carpetas separadas para conservar ambas construcciones.
RUN scons --ignore-style defconfig out/ARM_MOESI /opt/defconfigs/ARM_MOESI.defconfig \
    && scons --ignore-style --limit-ld-memory-usage out/ARM_MOESI/gem5.opt -j${JOBS}


# Esta seccion tiene como objetivo el constrir la libreria libm5.a para programas ARM de 64 bits.
# Asimismo esta biblioteca permite usar operaciones como resetear y volcar las estadisticas desde el programa simulado.
# Finalmente, tambien va a comprobar que ambos simuladores respondan a --version.
RUN scons -C util/m5 build/arm64/out/libm5.a \
    && out/ARM_MESI/gem5.opt --build-info \
    && out/ARM_MOESI/gem5.opt --build-info

# Esta seccion va a registrar el commit del simulador gem5 y las versiones de paquetes instalados.
# Asimismo estos datos ayudan a identificar el entorno usado en las pruebas.
RUN git rev-parse HEAD > /opt/gem5-commit.txt \
    && dpkg-query -W > /opt/packages.txt

# Esta linea va a definir la carpeta de trabajo al iniciar el contenedor.
# El script arm_env.sh conecta aqui el repositorio de Ubuntu.
WORKDIR /work

# Esta linea debe abrir el Bash si no se proporciona otro comando al ejecutar la imagen.
CMD ["bash"]
