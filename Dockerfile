ARG REGISTRY="docker.io"
FROM ${REGISTRY}/golang:latest AS go
RUN git clone --depth 1 https://github.com/volatilityfoundation/dwarf2json.git \
    && cd dwarf2json \
    && go build

FROM ${REGISTRY}/ubuntu:22.04 AS base
RUN apt-get update && apt-get -y install \
    build-essential git wget libncurses-dev bc curl \
    gdb xonsh flex bison libssl-dev libelf-dev pigz \
    bsdmainutils zstd cpio ccache && \
    rm -rf /var/lib/apt/lists/*
# dwarf2json
RUN wget https://github.com/volatilityfoundation/dwarf2json/releases/download/v0.9.0/dwarf2json-linux-amd64 -O /bin/dwarf2json && \
	chmod +x /bin/dwarf2json
RUN mkdir -p /opt/cross && echo '#!/bin/sh' > /opt/cross/setup-cross.sh && chmod +x /opt/cross/setup-cross.sh
COPY --from=go /go/dwarf2json/dwarf2json /bin/dwarf2json

# i686
FROM base AS i686
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/i686-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/i686-linux-musl-cross /opt/cross/i686-linux-musl && \
    echo 'ln -sf /opt/cross/i686-linux-musl-cross /opt/cross/i686-linux-musl' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/i686-linux-musl/bin:${PATH}"

# x86_64
FROM base AS x86_64
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/x86_64-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/x86_64-linux-musl-cross /opt/cross/x86_64-linux-musl && \
    echo 'ln -sf /opt/cross/x86_64-linux-musl-cross /opt/cross/x86_64-linux-musl' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/x86_64-linux-musl/bin:${PATH}"

# armel
FROM base AS armel
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/arm-linux-musleabi-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/arm-linux-musleabi-cross /opt/cross/arm-linux-musleabi && \
    echo 'ln -sf /opt/cross/arm-linux-musleabi-cross /opt/cross/arm-linux-musleabi' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/arm-linux-musleabi/bin:${PATH}"

# arm64
FROM base AS arm64
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/aarch64-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/aarch64-linux-musl-cross /opt/cross/aarch64-linux-musl && \
    echo 'ln -sf /opt/cross/aarch64-linux-musl-cross /opt/cross/aarch64-linux-musl' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/aarch64-linux-musl/bin:${PATH}"

# mipseb
FROM base AS mipseb
RUN mkdir -p /opt/cross && \
    wget http://panda.re/secret/mipseb-linux-musl_gcc-5.3.0.tar.gz -O - | tar -xz -C /opt/cross && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/mipseb-linux-musl/bin:${PATH}"

# mipsel
FROM base AS mipsel
RUN mkdir -p /opt/cross && \
    wget http://panda.re/secret/mipsel-linux-musl_gcc-5.3.0.tar.gz -O - | tar -xz -C /opt/cross && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/mipsel-linux-musl/bin:${PATH}"

# mips64eb
FROM base AS mips64eb
RUN mkdir -p /opt/cross && \
    wget http://panda.re/secret/mips64-linux-musl-cross_gcc-6.5.0.tar.gz -O - | tar -xz -C /opt/cross && \
    echo 'ln -sf /opt/cross/mips64-linux-musl-cross /opt/cross/mips64eb-linux-musl' >> /opt/cross/setup-cross.sh && \
    # Dynamically create symlinks for every tool: mips64-linux-musl-* -> mips64eb-linux-musl-*
    echo 'for f in /opt/cross/mips64eb-linux-musl/bin/mips64-linux-musl-*; do [ -e "$f" ] || continue; b=$(basename "$f"); suf=${b#mips64-linux-musl-}; ln -sf "$f" "/opt/cross/mips64eb-linux-musl/bin/mips64eb-linux-musl-$suf"; done' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/mips64eb-linux-musl/bin:${PATH}"

# mips64el
# musl-cross mips64el
# custom mips64 toolchain
# mips64 toolchain built using https://github.com/richfelker/musl-cross-make
# BINUTILS_VER = 2.25.1
# GCC_VER = 6.5.0
# MUSL_VER = git-v1.1.24
# GMP_VER = 6.1.0
# MPC_VER = 1.0.3
# MPFR_VER = 3.1.4
# GCC_CONFIG += --enable-languages=c
# It's a bit nutty to symlink all of these, but easier to keep track of what's needed for the future
FROM base AS mips64el
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/mips64el-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/mips64el-linux-musl-cross /opt/cross/mips64el-linux-musl && \
    echo 'ln -sf /opt/cross/mips64el-linux-musl-cross /opt/cross/mips64el-linux-musl' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/mips64el-linux-musl/bin:${PATH}"

# arm
FROM base AS arm
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/arm-linux-musleabi-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/arm-linux-musleabi-cross /opt/cross/arm-linux-musleabi && \
    echo 'ln -sf /opt/cross/arm-linux-musleabi-cross /opt/cross/arm-linux-musleabi' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/arm-linux-musleabi/bin:${PATH}"

# armhf
FROM base AS armhf
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/arm-linux-musleabihf-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/arm-linux-musleabihf-cross /opt/cross/arm-linux-musleabihf && \
    echo 'ln -sf /opt/cross/arm-linux-musleabihf-cross /opt/cross/arm-linux-musleabihf' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/arm-linux-musleabihf/bin:${PATH}"

# riscv32
FROM base AS riscv32
RUN apt-get update && apt-get install -y gcc-riscv64-linux-gnu && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/riscv32-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/riscv32-linux-musl-cross /opt/cross/riscv32-linux-musl && \
    echo 'ln -sf /opt/cross/riscv32-linux-musl-cross /opt/cross/riscv32-linux-musl' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/riscv32-linux-musl/bin:${PATH}"

# riscv64
FROM base AS riscv64
RUN apt-get update && apt-get install -y gcc-riscv64-linux-gnu && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/riscv64-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/riscv64-linux-musl-cross /opt/cross/riscv64-linux-musl && \
    echo 'ln -sf /opt/cross/riscv64-linux-musl-cross /opt/cross/riscv64-linux-musl' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/riscv64-linux-musl/bin:${PATH}"

# powerpc64
FROM base AS powerpc64
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/powerpc64-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/powerpc64-linux-musl-cross /opt/cross/powerpc64-linux-musl && \
    echo 'ln -sf /opt/cross/powerpc64-linux-musl-cross /opt/cross/powerpc64-linux-musl' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/powerpc64-linux-musl/bin:${PATH}"

# powerpc64le
FROM powerpc64 AS powerpc64le
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/powerpc64le-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/powerpc64le-linux-musl-cross /opt/cross/powerpc64le-linux-musl && \
    echo 'ln -sf /opt/cross/powerpc64le-linux-musl-cross /opt/cross/powerpc64le-linux-musl' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/powerpc64le-linux-musl/bin:${PATH}"

# powerpc
FROM powerpc64 AS powerpc
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/powerpc-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/powerpc-linux-musl-cross /opt/cross/powerpc-linux-musl && \
    echo 'ln -sf /opt/cross/powerpc-linux-musl-cross /opt/cross/powerpc-linux-musl' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/powerpc-linux-musl/bin:${PATH}"

# powerpcle
FROM powerpc64 AS powerpcle
RUN mkdir -p /opt/cross && \
    wget https://musl.cc/powerpcle-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && \
    ln -s /opt/cross/powerpcle-linux-musl-cross /opt/cross/powerpcle-linux-musl && \
    echo 'ln -sf /opt/cross/powerpcle-linux-musl-cross /opt/cross/powerpcle-linux-musl' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/powerpcle-linux-musl/bin:${PATH}"

# loongarch64
FROM base AS loongarch64
RUN mkdir -p /opt/cross && \
    wget https://github.com/loongson/build-tools/releases/download/2025.02.21/x86_64-cross-tools-loongarch64-binutils_2.44-gcc_14.2.0-glibc_2.41.tar.xz -O - | tar -xJ -C /tmp && \
    mv /tmp/cross-tools/ /opt/cross/loongarch64-linux-gcc-cross && \
    ln -s /opt/cross/loongarch-linux-gcc-cross /opt/cross/loongarch-linux-musl && \
    echo 'ln -sf /opt/cross/loongarch64-linux-gcc-cross /opt/cross/loongarch-linux-musl' >> /opt/cross/setup-cross.sh && \
    bash /opt/cross/setup-cross.sh
ENV PATH="/opt/cross/loongarch64-linux-gcc-cross/bin:${PATH}"

# final stage: gather all toolchains
FROM base AS final
RUN apt-get update && \
    apt-get install -y gcc-riscv64-linux-gnu && \
    rm -rf /var/lib/apt/lists/*
COPY --from=i686         /opt/cross /opt/cross
ENV PATH="/opt/cross/i686-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=x86_64       /opt/cross /opt/cross
ENV PATH="/opt/cross/x86_64-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=mipseb       /opt/cross /opt/cross
ENV PATH="/opt/cross/mipseb-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=mipsel       /opt/cross /opt/cross
ENV PATH="/opt/cross/mipsel-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=mips64eb     /opt/cross /opt/cross
ENV PATH="/opt/cross/mips64eb-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=mips64el     /opt/cross /opt/cross
ENV PATH="/opt/cross/mips64el-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=armel        /opt/cross /opt/cross
ENV PATH="/opt/cross/arm-linux-musleabi/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=armhf        /opt/cross /opt/cross
ENV PATH="/opt/cross/arm-linux-musleabihf/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=arm64        /opt/cross /opt/cross
ENV PATH="/opt/cross/aarch64-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=riscv32      /opt/cross /opt/cross
ENV PATH="/opt/cross/riscv32-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=riscv64      /opt/cross /opt/cross
ENV PATH="/opt/cross/riscv64-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=powerpc      /opt/cross /opt/cross
ENV PATH="/opt/cross/powerpc-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=powerpcle    /opt/cross /opt/cross
ENV PATH="/opt/cross/powerpcle-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=powerpc64    /opt/cross /opt/cross
ENV PATH="/opt/cross/powerpc64-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=powerpc64le  /opt/cross /opt/cross
ENV PATH="/opt/cross/powerpc64le-linux-musl/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh
COPY --from=loongarch64  /opt/cross /opt/cross
ENV PATH="/opt/cross/loongarch64-linux-gcc-cross/bin:${PATH}"
RUN bash /opt/cross/setup-cross.sh && rm -rf /opt/cross/setup-cross.sh

# rust stage (unchanged, can be added as needed)
FROM final AS rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"
# XXX: pin rust version to 1.71 until we figure out a workaround for mips linux being demoted to tier 3
RUN rustup toolchain install 1.71 --allow-downgrade --profile minimal # Now install 1.71
RUN rustup override set 1.71 # and switch to it
# Cross tools
RUN  rustup target add x86_64-unknown-linux-musl && \
     rustup target add mips-unknown-linux-musl && \
     rustup target add mipsel-unknown-linux-musl && \
     rustup target add mips64-unknown-linux-gnuabi64 && \
     rustup target add mips64-unknown-linux-muslabi64 && \
     rustup target add arm-unknown-linux-musleabi && \
     rustup target add arm-unknown-linux-musleabihf && \
     rustup target add aarch64-unknown-linux-musl
    
# Now we can use a cargo/.config with something like the following (as seen in the vpn package)
#[target.mips-unknown-linux-musl]
#linker = "/opt/cross/mipseb-linux-musl/bin/mipseb-linux-musl-gcc"
#[target.mipsel-unknown-linux-musl]
#linker = "/opt/cross/mipsel-linux-musl/bin/mipsel-linux-musl-gcc"
#[target.arm-unknown-linux-musleabi]
#linker = "/opt/cross/arm-linux-musleabi/bin/arm-linux-musleabi-gcc"
    
# Now we can use a cargo/.config with something like the following (as seen in the vpn package)
#[target.mips-unknown-linux-musl]
#linker = "/opt/cross/mipseb-linux-musl/bin/mipseb-linux-musl-gcc"
#[target.mipsel-unknown-linux-musl]
#linker = "/opt/cross/mipsel-linux-musl/bin/mipsel-linux-musl-gcc"
#[target.arm-unknown-linux-musleabi]
#linker = "/opt/cross/arm-linux-musleabi/bin/arm-linux-musleabi-gcc"
#linker = "/opt/cross/mipseb-linux-musl/bin/mipseb-linux-musl-gcc"
#[target.mipsel-unknown-linux-musl]
#linker = "/opt/cross/mipsel-linux-musl/bin/mipsel-linux-musl-gcc"
#[target.arm-unknown-linux-musleabi]
#linker = "/opt/cross/arm-linux-musleabi/bin/arm-linux-musleabi-gcc"
