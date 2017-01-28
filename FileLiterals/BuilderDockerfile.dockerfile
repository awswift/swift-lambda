FROM swift
RUN apt-get update
RUN apt-get install -y zip
WORKDIR /app
COPY .swift-lambda/index.js .build/debug/
COPY .swift-lambda/resolvedDeps.py .build/debug/
RUN cd .build/debug && zip /app/lambda.zip index.js
<aptDependencies>
COPY Package.swift .
RUN swift package fetch
COPY . .
RUN swift build
WORKDIR .build/debug
RUN ldd <packageName> | python resolvedDeps.py | xargs zip /app/lambda.libs.zip -j
RUN mv <packageName> swiftLambdaEntrypoint
RUN zip /app/lambda.zip swiftLambdaEntrypoint
