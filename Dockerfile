# 第一阶段：构建 Lethe CFD
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04 AS builder

# 安装基础依赖
RUN apt update && apt install -y \
    build-essential cmake git wget curl \
    libopenmpi-dev openmpi-bin \
    libboost-all-dev \
    libeigen3-dev \
    libtbb-dev \
    libhdf5-dev \
    libnetcdf-dev \
    libgmp-dev libmpfr-dev \
    libvtk9-dev \
    libp4est-dev \
    vim nano unzip \
    python3 python3-pip

# 安装 Miniconda（用于方法三）
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh && \
    /opt/conda/bin/conda init bash

ENV PATH=/opt/conda/bin:$PATH
# 安装 PETSc（方法二：源码安装）
RUN git clone https://gitlab.com/petsc/petsc.git /petsc && \
    cd /petsc && \
    ./configure && make all && make install || echo "PETSc 源码安装失败，建议使用 Conda 安装 petsc4py"

# 安装 Trilinos（方法二：源码安装）
RUN git clone https://github.com/trilinos/Trilinos.git /trilinos && \
    mkdir -p /trilinos/build && cd /trilinos/build && \
    cmake .. && make -j$(nproc) || echo "Trilinos 源码安装失败，请手动安装或跳过"

# 安装 deal.II（方法二：源码安装）
RUN git clone https://github.com/dealii/dealii.git /dealii && \
    mkdir -p /dealii/build && cd /dealii/build && \
    cmake .. && make -j$(nproc) || echo "deal.II 源码安装失败，请手动安装或跳过"

# 克隆 Lethe CFD
RUN git clone https://github.com/chaos-polymtl/lethe.git /lethe

# 构建 Lethe CFD
WORKDIR /lethe
RUN mkdir -p build && cd build && \
    cmake -DLETHE_BUILD_CFD=ON \
          -DLETHE_BUILD_PINN=OFF .. && \
    make -j$(nproc)

# 第二阶段：精简镜像，仅保留可执行文件
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04
# 拷贝可执行文件
COPY --from=builder /lethe/build/lethe_solver /lethe_solver

# 设置工作目录和默认命令
WORKDIR /app
CMD ["/lethe_solver", "/app/config/simulation.prm"]

# 挂载配置与数据目录
VOLUME ["/app/config", "/app/data"]
