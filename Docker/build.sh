#!/bin/bash
cd "$(dirname ${BASH_SOURCE[0]})"
docker build -t awswift/swift-deps:$TAG -f Dockerfile.deps .
docker build -t awswift/swiftda:$TAG -f Dockerfile.swiftda .
docker build -t awswift/swift-compiler:$TAG -f Dockerfile.swiftbuild .
