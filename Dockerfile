# 使用 CUDA 支持的基础镜像
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04

# 设置非交互模式
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
    make -j4
# 清理构建缓存以减小镜像体积
RUN rm -rf /var/lib/apt/lists/* /opt/spack/var/spack/cache
# 设置默认工作目录
WORKDIR /lethe/build

# 设置默认启动命令（可根据需要修改）
CMD ["/bin/bash"]
