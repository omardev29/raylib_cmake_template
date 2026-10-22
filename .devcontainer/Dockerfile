# Debian 13 (trixie): CMake 3.31 (el template pide 3.25+) y tcc.
# Si la etiqueta no existe, usa :bookworm (Debian 12).
FROM mcr.microsoft.com/devcontainers/base:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build pkg-config git gdb \
        tcc \
        clangd \
        feh \
        libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libgl-dev \
        libgl1-mesa-dri libglx-mesa0 mesa-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
