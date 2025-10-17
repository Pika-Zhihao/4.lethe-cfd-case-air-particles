# 第一阶段：构建 deal.II 和 Lethe CFD
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04 AS builder

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

# 安装 Spack 并构建 deal.II
RUN git clone https://github.com/spack/spack.git /opt/spack
ENV SPACK_ROOT=/opt/spack
RUN bash -c "source /opt/spack/share/spack/setup-env.sh && \
             spack install dealii +mpi +petsc +trilinos +hdf5 +p4est +vtk"

# 构建 Lethe CFD
RUN git clone https://github.com/chaos-polymtl/lethe.git /lethe
WORKDIR /lethe
RUN mkdir build && cd build && \
    bash -c "source /opt/spack/share/spack/setup-env.sh && \
             spack load dealii && \
             cmake -DDEAL_II_DIR=$(spack location -i dealii) \
                   -DLETHE_BUILD_CFD=ON \
                   -DLETHE_BUILD_PINN=OFF .. && \
             make -j$(nproc)"

# 第二阶段：精简镜像，仅保留可执行文件
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04

COPY --from=builder /lethe/build/lethe_solver /lethe_solver

WORKDIR /app
CMD ["/lethe_solver", "/app/config/simulation.prm"]

VOLUME ["/app/config", "/app/data"]
