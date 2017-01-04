FROM awswift/swiftda:0.1
RUN yum -y install openssl-devel
WORKDIR /app
RUN mkdir -p .build/debug
RUN cp /usr/lib/swift/linux/*.so* .build/debug/
COPY .swiftda/index.js .build/debug/
RUN cd .build/debug && zip /app/lambda.zip *.so* index.js
COPY Package.swift .
RUN swift package fetch
COPY . .
RUN swift build
WORKDIR .build/debug
RUN mv <packageName> swiftdaEntrypoint
RUN zip /app/lambda.zip swiftdaEntrypoint
