# Swiftda.json manifest

Projects utilising the Swiftda project include a `Swiftda.json` manifest file
in their root directory alongside SwiftPM's `Package.swift`. This file is
mandatory and includes information that Swiftda needs in order to successfully
deploy your function to AWS Lambda.

## Basic

In its basic form, this is a JSON file that looks like the following:

```json
{
    "Name": "Swifty McLambdaface",
    "Description": "My awesome new backend function written in Swift",
    "Memory": 128,
    "Timeout": 30,
    "YumDependencies": [
        "openssl-devel"
    ]
}
```

* The `Name` field is how we refer to our function. AWS Lambda lets you define
  as many functions as you need, so being able to refer to them by name is 
  helpful.
* The `Description` field is similarly useful for distinguishing between 
  Lambda functions when you have many defined.
* The `Memory` field is mandatory and should be an integer between 128 and 1536.
  This is how much memory Lambda will make available to your Swift program
  while it runs. CPU performance is also allocated to your function proportionate
  to the amount of memory allocated.
* The `Timeout` field is a mandatory integer between 1 and 300. This is how many
  seconds that Lambda will wait before considering your function to have timed
  out and be forcibly terminated. You are billed per 100ms of actual runtime,
  not how much time you allocate.
* The `YumDependencies` field is optional. It is an array of native dependencies
  that your Swift program (or its packages) needs in order to compile.

## Advanced

Eventually your needs may exceed that provided by the basic manifest file
format. In this case, you can upgrade to using an AWS [CloudFormation][cfn]
template to describe your function and infrastracture-as-code.

CloudFormation allows you to describe database tables, push notification topics,
S3 file upload buckets and any other AWS resources you might need in addition
to your Lambda function to support your mobile application.

Here is an example of a CloudFormation Swiftda manifest file:

```json
{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Metadata": {
        "Name": ""
    },
    "Resources": {

    },
}
```

## CloudFormation rationale

Our rationale for exposing raw CloudFormation is that a) you shouldn't have
to learn a new standard when an existing one will do and b) we don't want to
reinvent the wheel.

[cfn]: https://aws.amazon.com/cloudformation/
