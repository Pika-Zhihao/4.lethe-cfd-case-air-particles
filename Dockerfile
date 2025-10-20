# 第一阶段：构建 deal.II 和 Lethe CFD
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04 AS builder

# 安装依赖
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
    vim nano unzip

# 安装 Spack
RUN git clone https://github.com/spack/spack.git /opt/spack
ENV SPACK_ROOT=/opt/spack
ENV PATH=$SPACK_ROOT/bin:$PATH

# 禁用 Spack 编译器包装器
ENV SPACK_NO_COMPILER_WRAPPERS=1

# 安装 deal.II（使用 Spack 安装，但不使用 wrapper）
RUN bash -c "source /opt/spack/share/spack/setup-env.sh && \
             spack install dealii +mpi +petsc +trilinos +hdf5 +p4est +vtk"

# 克隆 Lethe CFD
RUN git clone https://github.com/chaos-polymtl/lethe.git /lethe

# 构建 Lethe CFD（使用系统编译器 + 手动指定 deal.II 路径）
WORKDIR /lethe
RUN bash -c "\
    source /opt/spack/share/spack/setup-env.sh && \
    export SPACK_NO_COMPILER_WRAPPERS=1 && \
    export CXX=/usr/bin/g++ && \
    export CC=/usr/bin/gcc && \
    DEAL_II_DIR=$(spack location -i dealii)/share/deal.II/cmake && \
    mkdir -p build && cd build && \
    cmake -DDEAL_II_DIR=$DEAL_II_DIR \
          -DLETHE_BUILD_CFD=ON \
          -DLETHE_BUILD_PINN=OFF .. && \
    make -j$(nproc)"

# 第二阶段：精简镜像，仅保留可执行文件
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04

# 拷贝可执行文件
COPY --from=builder /lethe/build/lethe_solver /lethe_solver
# 设置工作目录和默认命令
WORKDIR /app
CMD ["/lethe_solver", "/app/config/simulation.prm"]

# 挂载配置与数据目录
VOLUME ["/app/config", "/app/data"]
