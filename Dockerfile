ARG REGISTRY="docker.io"
FROM ${REGISTRY}/ubuntu:22.04 AS base
RUN apt-get update
RUN apt-get -y install build-essential git wget libncurses-dev bc curl
RUN mkdir -p /opt/cross

# musl-cross i686
ENV PATH="/opt/cross/i686-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/i686-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && ln -s /opt/cross/i686-linux-musl-cross /opt/cross/i686-linux-musl
# musl-cross x86_64
ENV PATH="/opt/cross/x86_64-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/x86_64-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && ln -s /opt/cross/x86_64-linux-musl-cross /opt/cross/x86_64-linux-musl

# musl-cross mipseb,mipsel
# Latest mips and mipsel toolchains break on building old kernels so we use these with gcc 5.3.0
ENV PATH="/opt/cross/mipseb-linux-musl/bin/:${PATH}"
RUN wget http://panda.re/secret/mipseb-linux-musl_gcc-5.3.0.tar.gz -O - | tar -xz -C /opt/cross
ENV PATH="/opt/cross/mipsel-linux-musl/bin/:${PATH}"
RUN wget http://panda.re/secret/mipsel-linux-musl_gcc-5.3.0.tar.gz -O - | tar -xz -C /opt/cross

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
ENV PATH="/opt/cross/mips64eb-linux-musl/bin/:${PATH}"
RUN wget http://panda.re/secret/mips64-linux-musl-cross_gcc-6.5.0.tar.gz -O - | tar -xz -C /opt/cross &&  ln -s /opt/cross/mips64-linux-musl-cross /opt/cross/mips64eb-linux-musl && \ 
    ln -s /opt/cross/mips64eb-linux-musl/bin/mips64-linux-musl-gcc /opt/cross/mips64eb-linux-musl/bin/mips64eb-linux-musl-gcc && \
    ln -s /opt/cross/mips64eb-linux-musl/bin/mips64-linux-musl-ld /opt/cross/mips64eb-linux-musl/bin/mips64eb-linux-musl-ld && \
    ln -s /opt/cross/mips64eb-linux-musl/bin/mips64-linux-musl-objdump /opt/cross/mips64eb-linux-musl/bin/mips64eb-linux-musl-objdump && \
    ln -s /opt/cross/mips64eb-linux-musl/bin/mips64-linux-musl-objcopy /opt/cross/mips64eb-linux-musl/bin/mips64eb-linux-musl-objcopy && \
    ln -s /opt/cross/mips64eb-linux-musl/bin/mips64-linux-musl-ar /opt/cross/mips64eb-linux-musl/bin/mips64eb-linux-musl-ar && \
    ln -s /opt/cross/mips64eb-linux-musl/bin/mips64-linux-musl-nm /opt/cross/mips64eb-linux-musl/bin/mips64eb-linux-musl-nm && \
    ln -s /opt/cross/mips64eb-linux-musl/bin/mips64-linux-musl-strip /opt/cross/mips64eb-linux-musl/bin/mips64eb-linux-musl-strip

# musl-cross mips64el
ENV PATH="/opt/cross/mips64el-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/mips64el-linux-musl-cross.tgz -O -  | tar -xz -C /opt/cross &&  ln -s /opt/cross/mips64el-linux-musl-cross /opt/cross/mips64el-linux-musl 
# musl-cross arm
ENV PATH="/opt/cross/arm-linux-musleabi/bin/:${PATH}"
RUN wget https://musl.cc/arm-linux-musleabi-cross.tgz -O - | tar -xz -C /opt/cross &&  ln -s /opt/cross/arm-linux-musleabi-cross /opt/cross/arm-linux-musleabi
# musl-cross armhf
ENV PATH="/opt/cross/arm-linux-musleabihf/bin/:${PATH}"
RUN wget https://musl.cc/arm-linux-musleabihf-cross.tgz -O - | tar -xz -C /opt/cross &&  ln -s /opt/cross/arm-linux-musleabihf-cross /opt/cross/arm-linux-musleabihf
# musl-cross arm64
ENV PATH="/opt/cross/aarch64-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/aarch64-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && ln -s /opt/cross/aarch64-linux-musl-cross /opt/cross/aarch64-linux-musl 

# musl-cross riscv32
ENV PATH="/opt/cross/riscv32-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/riscv32-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && ln -s /opt/cross/riscv32-linux-musl-cross /opt/cross/riscv32-linux-musl 

# musl-cross riscv64
ENV PATH="/opt/cross/riscv64-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/riscv64-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && ln -s /opt/cross/riscv64-linux-musl-cross /opt/cross/riscv64-linux-musl

# musl-cross ppc
ENV PATH="/opt/cross/powerpc-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/powerpc-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && ln -s /opt/cross/powerpc-linux-musl-cross /opt/cross/powerpc-linux-musl

# musl-cross ppcle
ENV PATH="/opt/cross/powerpcle-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/powerpcle-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && ln -s /opt/cross/powerpcle-linux-musl-cross /opt/cross/powerpcle-linux-musl


# musl-cross ppc64
ENV PATH="/opt/cross/powerpc64-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/powerpc64-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && ln -s /opt/cross/powerpc64-linux-musl-cross /opt/cross/powerpc64-linux-musl

# musl-cross ppc64le
ENV PATH="/opt/cross/powerpc64le-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/powerpc64le-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && ln -s /opt/cross/powerpc64le-linux-musl-cross /opt/cross/powerpc64le-linux-musl

# gcc loongson
ENV PATH="/opt/cross/loongarch64-linux-gcc-cross/bin/:${PATH}"
RUN wget https://github.com/loongson/build-tools/releases/download/2025.02.21/x86_64-cross-tools-loongarch64-binutils_2.44-gcc_14.2.0-glibc_2.41.tar.xz -O - | tar -xJ -C /tmp && mv /tmp/cross-tools/ /opt/cross/loongarch64-linux-gcc-cross && ln -s /opt/cross/loongarch-linux-gcc-cross /opt/cross/loongarch-linux-musl

# rust
FROM base AS rust
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
