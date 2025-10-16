FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# 安装基础依赖
RUN apt update && apt install -y \
    build-essential cmake git wget curl \
    python3 python3-pip \
    libopenmpi-dev openmpi-bin \
    libboost-all-dev \
    libeigen3-dev \
    libtbb-dev \
    libhdf5-dev \
    libnetcdf-dev \
    libgmp-dev libmpfr-dev \
    vim nano unzip \
    && rm -rf /var/lib/apt/lists/*

# 安装 Spack
RUN git clone https://github.com/spack/spack.git /opt/spack
ENV SPACK_ROOT=/opt/spack
RUN echo ". /opt/spack/share/spack/setup-env.sh" >> /etc/profile

# 安装 deal.II（含所有依赖）
SHELL ["/bin/bash", "-c"]
RUN . /opt/spack/share/spack/setup-env.sh && \
    spack install dealii +mpi +petsc +trilinos +hdf5 +p4est +vtk

# 设置 deal.II 路径
RUN . /opt/spack/share/spack/setup-env.sh && \
    spack load dealii && \
    echo "export DEAL_II_DIR=$(spack location -i dealii)" >> ~/.bashrc

# 克隆并构建 Lethe
RUN git clone https://github.com/chaos-polymtl/lethe.git /lethe
WORKDIR /lethe
RUN mkdir build && cd build && \
    . /opt/spack/share/spack/setup-env.sh && \
    spack load dealii && \
    cmake -DDEAL_II_DIR=$DEAL_II_DIR .. && \
    make -j$(nproc)
