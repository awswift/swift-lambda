FROM awswift/amazonlinux:0.1
ARG AWS_REGION=ap-southeast-2
RUN echo ${AWS_REGION} > /etc/yum/vars/awsregion

RUN yum-config-manager --enable epel
RUN yum install -y \
    clang \
    clang-devel \
    cpp \
    gcc \
    gcc-c++ \
    glibc \
    glibc-devel \
    libgcc \
    libgomp \
    libbsd-devel \
    libmpc \
    libstdc++ \
    libstdc++-devel \
    llvm \
    llvm-devel \
    llvm-libs \
    mpfr \
    libtool \
    libcurl-devel \
    git \
    cmake3 \
    re2c \
    uuid-devel \
    libuuid-devel \
    icu \
    libicu \
    libicu-devel \
    libedit-devel \
    libxml2-devel \
    sqlite-devel \
    swig \
    ncurses-devel \
    python-devel \
    pkgconfig \
    autoconf \
    automake

COPY libkqueue-2.0.1-1.x86_64.rpm .
COPY libkqueue-devel-2.0.1-1.x86_64.rpm .
RUN rpm -Uvh libkqueue-*

RUN sed -i.bak s/__block/___block/g /usr/include/unistd.h
RUN ln -s /usr/bin/cmake3 /usr/bin/cmake
RUN ln -s /usr/lib/gcc/x86_64-amazon-linux /usr/lib/gcc/x86_64-linux-gnu
RUN ln -s /usr/include/c++/4.8.3/x86_64-amazon-linux /usr/include/c++/4.8.3/x86_64-linux-gnu
