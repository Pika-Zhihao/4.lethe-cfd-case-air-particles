FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
# 安装依赖
RUN apt update && apt install -y \
    build-essential cmake git wget curl \
    libopenmpi-dev openmpi-bin \
    libboost-all-dev \
    libhdf5-dev \
    python3 python3-pip \
    libvtk7-dev \
    libtbb-dev \
    libeigen3-dev \
    libpetsc-dev petsc-dev \
    libnetcdf-dev \
    libgmp-dev libmpfr-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装 deal.II（Lethe CFD 依赖）
RUN git clone https://github.com/dealii/dealii.git /dealii && \
    cd /dealii && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/dealii-install -DDEAL_II_WITH_MPI=ON .. && \
    make -j$(nproc) && make install

# 安装 Lethe CFD（官方仓库）
RUN git clone https://github.com/chaos-polymtl/lethe.git /lethe && \
    cd /lethe && \
    mkdir build && cd build && \
    cmake -DCMAKE_PREFIX_PATH="/dealii-install" .. && \
    make -j$(nproc)

WORKDIR /lethe/build
