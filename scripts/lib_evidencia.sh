#!/usr/bin/env bash
# Funciones compartidas por los barridos (se carga con `source`).
# Cada funcion tiene una sola responsabilidad y deja evidencia en disco.

GEM5_DIR=${GEM5_DIR:-/opt/gem5}
GEM5_BIN=${GEM5_BIN:-$GEM5_DIR/build/ARM_MESI/gem5.opt}
SE_PY=${SE_PY:-$GEM5_DIR/configs/deprecated/example/se.py}
LIBM5=${LIBM5:-$GEM5_DIR/util/m5/build/arm64/out/libm5.a}
CC_ARM=${CC_ARM:-aarch64-linux-gnu-gcc}
OBJDUMP_ARM=${OBJDUMP_ARM:-aarch64-linux-gnu-objdump}

# Hardware comun a todos los experimentos (igual que configs/configuracion_superescalar.sh de E2).
OPCIONES_SISTEMA=(
    --cpu-clock=2GHz --sys-clock=1GHz
    --caches --l2cache
    --l1i_size=32KiB --l1d_size=32KiB --l2_size=256KiB
    --l1i_assoc=2 --l1d_assoc=2 --l2_assoc=8
    --cacheline_size=64
    --mem-type=DDR3_1600_8x8 --mem-size="${MEM:-512MiB}"
)





error() { echo "ERROR: $*" >&2; exit 1; }

verificar_entorno() {
    [[ -x $GEM5_BIN ]] || error "falta $GEM5_BIN (entra con: bash scripts/arm_env.sh)"
    [[ -f $SE_PY && -f $LIBM5 ]] || error "faltan se.py o libm5.a en $GEM5_DIR"
    command -v "$CC_ARM" >/dev/null || error "falta el compilador $CC_ARM"
}

# registrar_entorno DIR: fecha, commit, herramientas y huella de gem5.
registrar_entorno() {
    local dir=$1 raiz=${RAIZ:?RAIZ sin definir}
    mkdir -p "$dir"
    {
        echo "fecha=$(date -Is)"
        echo "commit=$(git -c safe.directory='*' -C "$raiz" rev-parse HEAD 2>/dev/null || echo desconocido)"
        echo "archivos_modificados=$(git -c safe.directory='*' -C "$raiz" status --porcelain 2>/dev/null | wc -l)"
        echo "host=$(uname -srm) nproc=$(nproc)"
        echo "gem5_bin=$GEM5_BIN"
    } > "$dir/manifest.txt"
    { "$CC_ARM" --version | head -n1; } > "$dir/compiler.txt" || true
    { "$GEM5_BIN" --version 2>&1 | head -n3; } > "$dir/gem5_build_info.txt" || true
    sha256sum "$SE_PY" "$GEM5_BIN" > "$dir/gem5_sha256.txt"
}

# compilar_arm FUENTE BINARIO DIR_EVIDENCIA FLAGS...
compilar_arm() {
    local fuente=$1 binario=$2 dir=$3; shift 3
    mkdir -p "$dir" "$(dirname "$binario")"
    local cmd=("$CC_ARM" "$@" -static -DUSE_GEM5 "-I$GEM5_DIR/include" "$fuente" "$LIBM5" -lm -o "$binario")
    { printf '%q ' "${cmd[@]}"; echo; } > "$dir/build_command.txt"
    "${cmd[@]}" > "$dir/build.log" 2>&1 || { tail -n 30 "$dir/build.log" >&2; error "fallo la compilacion de $fuente"; }
    sha256sum "$fuente"  > "$dir/source.sha256"
    sha256sum "$binario" > "$dir/binary.sha256"
    { file "$binario"; ls -l "$binario"; } > "$dir/binary_info.txt"
    # Desensamblado del nucleo (incluye la funcion OpenMP multiplicar._omp_fn.N).
    { "$OBJDUMP_ARM" -d "$binario" 2>/dev/null |
        awk '/^[0-9a-f]+ <(multiplicar|calcular_filas)[^>]*>:/{p=1} p{print} /^$/{p=0}'; } \
        > "$dir/kernel_asm.txt" || true
}

# validar_corrida DIR LINEA_ESPERADA: escribe validation.txt; devuelve 1 si no pasa.
validar_corrida() {
    local dir=$1 esperado=$2 estado=PASS motivo="" bloques
    [[ $(cat "$dir/exit_code.txt" 2>/dev/null) == 0 ]] || { estado=FAIL; motivo+="gem5 termino con error; "; }
    grep -Fxq "$esperado" "$dir/run.log" 2>/dev/null || { estado=FAIL; motivo+="falta la linea esperada; "; }
    bloques=$(grep -c 'End Simulation Statistics' "$dir/stats.txt" 2>/dev/null || true)
    (( ${bloques:-0} >= 2 )) || { estado=FAIL; motivo+="menos de 2 bloques de estadisticas; "; }
    { echo "estado=$estado"; echo "esperado=$esperado"
      echo "bloques_stats=${bloques:-0}"; echo "motivo=${motivo:-ninguno}"; } > "$dir/validation.txt"
    [[ $estado == PASS ]]
}

# ejecutar_gem5 DIR NUCLEOS BINARIO "ARGS" LINEA_ESPERADA [--param ...]
ejecutar_gem5() {
    local dir=$1 nucleos=$2 binario=$3 args=$4 esperado=$5; shift 5
    rm -rf "$dir"; mkdir -p "$dir"
        local cmd=("$GEM5_BIN" -d "$dir" "$SE_PY" --cpu-type=ArmO3CPU --num-cpus="$nucleos"
               "${OPCIONES_SISTEMA[@]}" "$@" -c "$binario" -o "$args")
    { printf '%q ' "${cmd[@]}"; echo; } > "$dir/command.txt"
    local inicio=$SECONDS codigo=0
    "${cmd[@]}" < /dev/null > "$dir/run.log" 2>&1 || codigo=$?
    echo "$codigo" > "$dir/exit_code.txt"
    echo "$((SECONDS - inicio))" > "$dir/tiempo_real_s.txt"
    validar_corrida "$dir" "$esperado"
}

esperar_cupo() { while (( $(jobs -rp | wc -l) >= $1 )); do wait -n || true; done; }
contar_pass()  { grep -l '^estado=PASS' "$@" 2>/dev/null | wc -l || true; }
