# Quickstart

swift-lambda brings the power and ease-of-use of the Swift programming language 
to the scalability and buzzword-compliance of AWS Lambda. Use the tools you 
already know and love to power the backend of your mobile application.

## Installation

swift-lambda can be installed using [Homebrew](http://brew.sh):

    $ brew install --HEAD awswift/swift-lambda/swift-lambda

## Pre-requisites

* A Swift programming environment. On macOS, this means installing Xcode. On 
  Linux, it means downloading Swift from the official website.

* Docker. We use Docker to emulate a local version of the Linux-y AWS Lambda 
  runtime environment. Because Swift compiles to native code, we need to compile 
  the code on a computer that is as similar to Lambda as possible. 

  Note that this is still needed even if you are running on Ubuntu, because 
  Lambda is different enough from Ubuntu that compiling on your own machine 
  won't work.

* **Interim**: The [AWS CLI](https://aws.amazon.com/cli/). Porting the AWS APIs 
  is still a work in progress in the `awswift/Awswift` repo. Until that is complete 
  we have relied on shelling out to the CLI tool for the alpha release.

* **Interim**: The [`stackup`](https://github.com/realestate-com-au/stackup) Ruby 
  gem. This is a great utility for dealing with CloudFormation and we are shelling 
  out to it until such functionality has been replicated in a Swift library.

## Usage

### `swift lambda setup`

`setup` is a once-off command that will get an AWS account ready for Swift-powered 
AWS Lambda functions. Right now it creates an S3 bucket for storing your code and
an [IAM execution role][iam-exec-role] to grant your Lambda functions permission 
to write logs.

[iam-exec-role]: http://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role

### `swift lambda init <name>`

`init` will initialise a brand-new _Hello, World!_ Swift-powered AWS Lambda 
function. Everything you need to get up and running will be created for you. 
`<name>` is how you tell the `init` command what you want your function to 
be called!

### `swift lambda build`

`build` will create the Zip archive that you upload to AWS Lambda in order 
to run your code. swift-lambda will compile your code in a Lambda-like Docker 
container, zip it up (alongside the Swift runtime) and stick in a few extra 
files that Lambda requires you to have. 

### `swift lambda deploy [--new-version] [--skip-libs]`

`deploy` is how you get the Zip file from the previous command onto Lambda 
itself. You could upload the zip using the AWS web console, but we provide 
this convenience helper so you can iterate on your code as quickly as you 
can type.

`--skip-libs` skips uploading the native libraries that the Swift function
depends on. This makes for a much faster deployment process. Note that this
flag is temporary and will be automatically calculated and hence removed soon.

~~`--new-version` lets you take advantage of AWS Lambda [function versioning][fn-ver]. 
It will increment your function's version number with this latest upload.~~

[fn-ver]: http://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html

### `swift lambda logs [--tail]`

`logs` allows you to see everything you `print()` in your Lambda function from 
the comfort of your terminal. This can be invaluable while debugging to see 
what is going on.

`--tail` will output log lines to your terminal as they happen in real-time.

### `swift lambda destroy`

`destroy` deletes all artifacts of your Lambda function on AWS. Maybe you're 
done with a dev version of your code and ready to start a new project - 
stop paying for storage and cluttering up your Lambda web console.

### `swift lambda debug`

`debug` allows you to step through your Lambda function from within Xcode, 
as if you were running it locally.

### `swift lambda invoke [--async] [--local]`

`invoke` will execute your Lambda function and return its output to your 
terminal.

`--async` can be used for long-running Lambda functions where you don't want 
to wait for it to finish. You can still monitor its progress using `logs`.

`--local` will run your Lambda function inside a Lambda-like Docker container 
on your own computer. This might be preferable if you have no Internet 
connectivity and can't upload your function to AWS.

## Function structure

Beyond the Swift code itself, swift-lambda also needs a `swift-lambda.json` file to know 
a bit about your intentions for this code. It is a JSON file that has some of 
the values required for publishing your code to Lambda. The structure is as 
follows:

```json
{
    "Name": "Swifty McLambdaface",
    "Description": "My awesome new backend function written in Swift",
    "Memory": 128,
    "Timeout": 30
}
```

You will also have a `Package.swift` as per [Swift Package Manager][swift-pm] 
conventions. It can be as simple as:

```swift
import PackageDescription

let package = Package(
    name: "lambdaface",
    dependencies: [
        .Package(url: "https://github.com/awswift/swift-lambda-runtime", majorVersion: 0, minor: 1)
    ]
)
```

[swift-pm]: https://swift.org/package-manager/

Finally, the last required piece is `Sources/main.swift`. This is the entrypoint 
to the Swift executable that swift-lambda will call. An example file would be:

```swift
import Foundation
import SwiftLambdaRuntime

SwiftLambdaRuntime().run { event, context, callback in
    let name = event["name"] ?? "World" 
    callback(["output": "Hello, \(name)"])
}
```
