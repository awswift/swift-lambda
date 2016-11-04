FROM awswift/swift-deps:0.1

WORKDIR swiftbuild
RUN mkdir -p build/buildbot_linux/lldb-linux-x86_64/lib64/python2.7
RUN mkdir -p build/buildbot_linux/lldb-linux-x86_64/lib
RUN ln -s /swiftbuild/build/buildbot_linux/lldb-linux-x86_64/lib64/python2.7 /swiftbuild/build/buildbot_linux/lldb-linux-x86_64/lib/python2.7

RUN mkdir symroot
RUN mkdir -p package/usr/lib/swift/linux
RUN cp /usr/lib64/libbsd.so.0.6.0 package/usr/lib/swift/linux
RUN cd /swiftbuild/package/usr/lib/swift/linux/ && ln -s libbsd.so.0.6.0 libbsd.so.0

RUN git clone https://github.com/martine/ninja.git

RUN git clone https://github.com/apple/swift.git
WORKDIR /swiftbuild/swift
ARG SWIFT_TAG
ENV SWIFT_TAG ${SWIFT_TAG:-swift-DEVELOPMENT-SNAPSHOT-2016-12-07-a}
RUN utils/update-checkout --clone --tag $SWIFT_TAG 

COPY linuxpreset.ini ../

ENV BUILDTHREADS 36
RUN utils/build-script \
      --preset-file=/swiftbuild/linuxpreset.ini \
      --preset=buildbot_linux_build_fedora23 \
      install_destdir="/swiftbuild/package" \
      install_symroot="/swiftbuild/symroot" \
      installable_package="/swiftbuild/package/swift-linux-x86_64-amzn.tgz" \
      build_threads=$BUILDTHREADS

WORKDIR /
RUN tar -xvf /swiftbuild/package/swift-linux-x86_64-amzn.tgz --skip-old-files

# RUN git clone https://github.com/PerfectlySoft/PerfectTemplate.git
# WORKDIR /PerfectTemplate
# RUN swift package fetch
# RUN yum -y install openssl-devel
# RUN swift build -v
