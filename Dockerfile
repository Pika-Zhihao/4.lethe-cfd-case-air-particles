# 使用 CUDA 支持的基础镜像
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04

LABEL maintainer="Zhihao CFD Case <hzh19991218@163.com>"

ENV DEBIAN_FRONTEND=noninteractive

# 安装系统依赖
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

# 使用 bash shell
SHELL ["/bin/bash", "-c"]

# 安装 deal.II（含所有依赖）
RUN source /opt/spack/share/spack/setup-env.sh && \
    spack install dealii +mpi +petsc +trilinos +hdf5 +p4est +vtk && \
    spack load dealii && \
    echo "export DEAL_II_DIR=$(spack location -i dealii)" >> /etc/profile

# 克隆并构建 Lethe CFD
RUN git clone https://github.com/chaos-polymtl/lethe.git /lethe
WORKDIR /lethe
RUN mkdir build && cd build && \
    source /opt/spack/share/spack/setup-env.sh && \
    spack load dealii && \
    cmake -DDEAL_II_DIR=$(spack location -i dealii) \
          -DLETHE_BUILD_CFD=ON \
          -DLETHE_BUILD_PINN=OFF \
          .. && \
    make -j$(nproc)

# 清理构建缓存以减小镜像体积
RUN rm -rf /var/lib/apt/lists/* /opt/spack/var/spack/cache

# 设置默认工作目录
WORKDIR /lethe/build

# 设置默认启动命令（可根据需要修改）
CMD ["./lethe_solver", "/app/config/simulation.prm"]

# 暴露端口（可选）
EXPOSE 8888

# 设置挂载点
VOLUME ["/app/config", "/app/data"]
