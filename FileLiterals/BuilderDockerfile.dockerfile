FROM awswift/swiftda:0.1
WORKDIR /app
RUN mkdir -p .build/debug
RUN cp /usr/lib/swift/linux/*.so* .build/debug/
COPY .swift-lambda/index.js .build/debug/
RUN cd .build/debug && zip /app/lambda.zip *.so* index.js
<yumDependencies>
COPY Package.swift .
RUN swift package fetch
COPY . .
RUN swift build
WORKDIR .build/debug
RUN mv <packageName> swiftLambdaEntrypoint
RUN zip /app/lambda.zip swiftLambdaEntrypoint
