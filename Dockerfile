# 第一阶段：构建 Lethe CFD
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04 AS builder
# 设置非交互模式和时区为香港
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Hong_Kong
# 安装基础依赖
RUN apt update && apt install -y \
    tzdata \
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

# 设置时区（避免 tzdata 交互）
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# 安装 Miniconda（用于备用方案）
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh

ENV PATH=/opt/conda/bin:$PATH

# 安装 PETSc（源码优先，失败则 Conda 安装 petsc4py）
RUN git clone https://gitlab.com/petsc/petsc.git /petsc && \
    cd /petsc && \
    ./configure --prefix=/opt/petsc && \
    make all && make install \
    || (echo "PETSc 源码安装失败，尝试使用 Conda 安装 petsc4py" && \
        conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
        conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
        conda install -y petsc4py)

# 安装 Trilinos（源码优先，失败则跳过）
RUN git clone https://github.com/trilinos/Trilinos.git /trilinos && \
    mkdir -p /trilinos/build && cd /trilinos/build && \
    cmake .. && make -j$(nproc) \
    || echo "Trilinos 安装失败，跳过"

# 安装 deal.II（源码优先，失败则跳过）
RUN git clone https://github.com/dealii/dealii.git /dealii && \
    mkdir -p /dealii/build && cd /dealii/build && \
    cmake .. && make -j$(nproc) \
    || echo "deal.II 安装失败，跳过"

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

# 设置非交互模式和时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Hong_Kong
RUN apt update && apt install -y tzdata && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# 拷贝可执行文件
COPY --from=builder /lethe/build/lethe_solver /lethe_solver

# 设置工作目录和默认命令
WORKDIR /app
CMD ["/lethe_solver", "/app/config/simulation.prm"]

# 挂载配置与数据目录
VOLUME ["/app/config", "/app/data"]
