FROM ubuntu:22.04 as base
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
    ln -s /opt/cross/mips64eb-linux-musl/bin/mips64-linux-musl-nm /opt/cross/mips64eb-linux-musl/bin/mips64eb-linux-musl-nm

# musl-cross mips64el
ENV PATH="/opt/cross/mips64el-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/mips64el-linux-musl-cross.tgz -O -  | tar -xz -C /opt/cross &&  ln -s /opt/cross/mips64el-linux-musl-cross /opt/cross/mips64el-linux-musl 
# musl-cross arm
ENV PATH="/opt/cross/arm-linux-musleabi/bin/:${PATH}"
RUN wget https://musl.cc/arm-linux-musleabi-cross.tgz -O - | tar -xz -C /opt/cross &&  ln -s /opt/cross/arm-linux-musleabi-cross /opt/cross/arm-linux-musleabi
# musl-cross arm64
ENV PATH="/opt/cross/aarch64-linux-musl/bin/:${PATH}"
RUN wget https://musl.cc/aarch64-linux-musl-cross.tgz -O - | tar -xz -C /opt/cross && ln -s /opt/cross/aarch64-linux-musl-cross /opt/cross/aarch64-linux-musl 

# rust
FROM base as rust
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
     rustup target add arm-unknown-linux-musleabi
    
# Now we can use a cargo/.config with something like the following (as seen in the vpn package)
#[target.mips-unknown-linux-musl]
#linker = "/opt/cross/mipseb-linux-musl/bin/mipseb-linux-musl-gcc"
#[target.mipsel-unknown-linux-musl]
#linker = "/opt/cross/mipsel-linux-musl/bin/mipsel-linux-musl-gcc"
#[target.arm-unknown-linux-musleabi]
#linker = "/opt/cross/arm-linux-musleabi/bin/arm-linux-musleabi-gcc"