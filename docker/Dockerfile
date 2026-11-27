# ClaudeClang build image (dev + CI). Image name: claudeclangbuild
# (Docker image names must be lowercase, so "ClaudeCLangBuild" -> "claudeclangbuild")
FROM ubuntu:24.04

ARG LLVM_VERSION=21
ARG PICT_VERSION=v3.7.4
ENV DEBIAN_FRONTEND=noninteractive \
    LLVM_VERSION=${LLVM_VERSION}

# Base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates wget gnupg lsb-release software-properties-common \
        git make cmake ninja-build python3 python3-pip python3-venv \
        cppcheck cloc doxygen graphviz \
        libgtest-dev libgmock-dev googletest \
    && rm -rf /var/lib/apt/lists/*

# LLVM / Clang from apt.llvm.org
RUN wget -qO /tmp/llvm.sh https://apt.llvm.org/llvm.sh \
    && bash /tmp/llvm.sh ${LLVM_VERSION} \
    && apt-get install -y --no-install-recommends \
        clang-format-${LLVM_VERSION} clang-tidy-${LLVM_VERSION} \
        libc++-${LLVM_VERSION}-dev libc++abi-${LLVM_VERSION}-dev \
    && rm -rf /var/lib/apt/lists/* /tmp/llvm.sh \
    && for t in clang clang++ clang-format clang-tidy llvm-cov llvm-profdata llvm-symbolizer; do \
           ln -sf /usr/bin/$t-${LLVM_VERSION} /usr/local/bin/$t; \
       done

# Lizard (complexity / function length)
RUN pip3 install --no-cache-dir --break-system-packages lizard

# PICT (pairwise test generation)
# (PICT forces -Werror; newer Clang warnings break its build, so drop it for this tool only)
RUN git clone --depth 1 --branch ${PICT_VERSION} https://github.com/microsoft/pict.git /tmp/pict \
    && grep -rl -- '-Werror' /tmp/pict --include=CMakeLists.txt | xargs -r sed -i 's/-Werror//g' \
    && cmake -S /tmp/pict -B /tmp/pict/build -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
    && cmake --build /tmp/pict/build \
    && install -m 0755 "$(find /tmp/pict/build -type f -name pict -perm -u+x | head -1)" /usr/local/bin/pict \
    && rm -rf /tmp/pict

ENV CC=clang CXX=clang++
WORKDIR /workspace
CMD ["bash"]
