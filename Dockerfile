# 第一阶段：构建 Lethe CFD
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04 AS builder

# 安装依赖
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
    libpetsc-dev \
    libtrilinos-dev \
    libp4est-dev \
    deal.ii-dev \
    vim nano unzip

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
