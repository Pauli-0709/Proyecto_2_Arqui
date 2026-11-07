#!/usr/bin/env bash

# Esta seccion va a detener el script ante algun posible error o variables que no estan definidas.
set -euo pipefail

# Esta linea debe localizar la raiz del repositorio a partir de este archivo.
# Esto es importante para el funcionamiento aunque se invoque desde otra carpeta.
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

# Esta seccion va a utilizar Docker directamente cuando el usuario tiene permisos.
# Asimismo, si se necesita privilegios, lo ejecuta mediante la instruccion sudo.
docker_cli=(docker)

if ! docker info >/dev/null 2>&1; then
    docker_cli=(sudo docker)
fi

# Esta seccion no tiene argumentos, puesto que va abrir una terminal Bash dentro del contenedor.
# Asimismo, con argumentos, debe ejecutar el comando que se le indique.
if (($# == 0)); then
    set -- bash
fi

# En esta seccion debe habilitar la terminal interactiva solo cuando corresponde.
tty_args=()

if [[ -t 0 && -t 1 ]]; then
    tty_args=(-it)
fi

# Finalmente, esta seccion va a ejecutar la imagen que ya esta construida. Continuamente conecta el repositorio local con /work dentro del contenedor.
# Usa nuestro usuario para conservar la propiedad de los archivos.
# Es importante mencionar que el contenedor temporal se elimina al finalizar el proceso.
exec "${docker_cli[@]}" run --rm "${tty_args[@]}" \
    --user "$(id -u):$(id -g)" \
    --mount "type=bind,src=${project_dir},dst=/work" \
    --workdir /work \
    ghcr.io/pauli-0709/proyecto2-gem5:24.1.0.1-env2 "$@"
