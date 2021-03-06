import Foundation
import Commander
import Rainbow
import SwiftyJSON

func packageInfo() -> JSON {
    let (stdout, _) = try! ShellCommand.piped(command: "swift package dump-package", label: "pkg info")
    return JSON(data: stdout.data(using: .utf8)!)
}

func dockerfile() -> String {
    let packageName = packageInfo()["name"].stringValue
    return FileLiterals.BuilderDockerfile.replacingOccurrences(of: "<packageName>", with: packageName)
}

class BuildCommand {
    func command() throws {
        _ = try ShellCommand.piped(command: "mkdir -p .swift-lambda", label: nil)

        let dockerfilePath = ".swift-lambda/Dockerfile"
        var dockerfile = FileLiterals.BuilderDockerfile
        
        let packageName = packageInfo()["name"].stringValue
        dockerfile = dockerfile.replacingOccurrences(of: "<packageName>", with: packageName)
        
        let template = Template.parseTemplateAtPath(".")!
        let aptDeps = template.aptDependencies.sorted()
        let yumReplacement = aptDeps.count > 0 ? "RUN yum -y install \(aptDeps.joined(separator: " "))" : ""
        dockerfile = dockerfile.replacingOccurrences(of: "<aptDependencies>", with: yumReplacement)
        
        try dockerfile.write(toFile: dockerfilePath, atomically: true, encoding: .utf8)
        try FileLiterals.index.write(toFile: ".swift-lambda/index.js", atomically: true, encoding: .utf8)
        try FileLiterals.resolvedDeps.write(toFile: ".swift-lambda/resolvedDeps.py", atomically: true, encoding: .utf8)

        let imageId = "swift-lambda-builder-\(packageName):\(arc4random())"
        let containerId = "swift-lambda-\(packageName)-\(arc4random())"
        //    _ = ShellCommand.piped(command: "docker pull swift-lambda", label: "🐳 pull")
        _ = try ShellCommand.piped(command: "docker build -f \(dockerfilePath) -t \(imageId) .", label: "🐳 build")
        _ = try ShellCommand.piped(command: "docker run -i --name \(containerId) \(imageId) true", label: "🐳 container")
        _ = try ShellCommand.piped(command: "docker cp \(containerId):/app/lambda.zip \(packageName).lambda.zip", label: "copy zip")
        _ = try ShellCommand.piped(command: "docker cp \(containerId):/app/lambda.libs.zip \(packageName).lambda.libs.zip", label: "copy libs zip")
    }
}

struct CloudFormation {
    static func stackUp(name: String, template: URL, parameters: [String: String]) throws {
        let paramStr = parameters.reduce("") { result, tuple in "\(result) -o \(tuple.key)=\(tuple.value)" }
        _ = try ShellCommand.piped(command: "stackup \(name) up -t \(template.path) \(paramStr)", label: "☁️ cfn up")
    }

    static func stackDown(name: String) throws {
        _ = try ShellCommand.piped(command: "stackup \(name) down", label: "☁️ cfn down")
    }

    static func outputs(name: String) throws -> [String: String] {
        let cmd = "aws cloudformation describe-stacks --stack-name \(name) --query Stacks[0].Outputs"
        let (stdout, _) = try ShellCommand.piped(command: cmd, label: "☁️ cfn outputs")
        let json = JSON(data: stdout.data(using: .utf8)!)
        var outputs: [String: String] = [:]
        json.arrayValue.forEach { outputs[$0["OutputKey"].stringValue] = $0["OutputValue"].stringValue }
        return outputs
    }

    static func exports() throws -> [String: String] {
        let (stdout, _) = try ShellCommand.piped(command: "aws cloudformation list-exports", label: "☁️ cfn vals")
        let exportsJson = JSON(data: stdout.data(using: .utf8)!)["Exports"].arrayValue
        var exports: [String: String] = [:]
        exportsJson.forEach { exports[$0["Name"].stringValue] = $0["Value"].stringValue }
        return exports
    }
}

class DeployCommand {
    func command(newVersion: Bool, skipLibs: Bool) throws {
        let config = Template.parseTemplateAtPath(".")!

        let zipUrl = URL(string: "\(config.name).lambda.zip", relativeTo: config.url)!
        let zipPath = zipUrl.path

        guard FileManager.default.fileExists(atPath: zipPath) else {
            return
        }
        
//        let headLibs = try s3Head(bucket: config.bucket, key: "\(config.key).libs")
//        let md5 = headLibs["Metadata"]["MD5Checksum"].string
        if !skipLibs {
            _ = try ShellCommand.piped(command: "aws s3 cp \(config.name).lambda.libs.zip s3://\(config.bucket)/\(config.key).libs", label: "s3 cp libs")
        }

        _ = try ShellCommand.piped(command: "aws s3 cp \(zipPath) s3://\(config.bucket)/\(config.key)", label: "s3 cp")
        let s3version = try s3Head(bucket: config.bucket, key: config.key)["VersionId"].stringValue

        let params = [
            "S3Bucket": config.bucket,
            "S3Key": config.key,
            "S3ObjectVersion": s3version,
            "Role": config.role,
            "LibsS3Bucket": config.bucket,
            "LibsS3Key": "\(config.key).libs"
        ]

        let templateURL = URL(fileURLWithPath: ".swift-lambda/cloudformation.yml")
        try FileLiterals.CloudFormation.write(to: templateURL, atomically: true, encoding: .utf8)
        try CloudFormation.stackUp(name: config.name, template: templateURL, parameters: params)
    }
    
    func s3Head(bucket: String, key: String) throws -> JSON {
        let cmd = "aws s3api head-object --bucket \(bucket) --key \(key) --output json"
        let (stdout, _) = try ShellCommand.piped(command: cmd, label: "s3 head")
        return JSON(data: stdout.data(using: .utf8)!)
    }
}

extension String {
    func extractRegexFields(regex: NSRegularExpression) -> [String] {
        let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.characters.count))!
        let range = 0..<match.numberOfRanges
        return range.map { idx in
            let range = match.rangeAt(idx)
            return (self as NSString).substring(with: range)
        }

    }
}

class InvokeCommand {
    struct InvokeResponse {
        let tail: String
        let elapsed: String
        let billed: String
        let memory: String
        let usedMemory: String
    }
    
    func command(async: Bool, local: Bool) throws {
        let resp = try invoke(async: async, local: local)
        print(resp.tail)
        print("\("Elapsed : ".green.bold) \(resp.elapsed)")
        print("\("Billed  : ".green.bold) \(resp.billed)")
        print("\("Memory  : ".green.bold) \(resp.memory)")
        print("\("Used Mem: ".green.bold) \(resp.usedMemory)")
    }

    // TODO: leaky because of unit testing?
    func invoke(async: Bool, local: Bool) throws -> InvokeResponse {
        if async || local {
            fatalError("Not implemented yet")
        }

        let config = Template.parseTemplateAtPath(".")!

        let stackOutputs = try CloudFormation.outputs(name: config.name)
        let functionName = stackOutputs["FunctionName"]!

        let cmd = "aws lambda invoke --function-name \(functionName) --log-type Tail /dev/null"
        let (stdout, _) = try ShellCommand.piped(command: cmd, label: "ƛ invoke")
        let json = JSON(data: stdout.data(using: .utf8)!)
        let logb64 = json["LogResult"].stringValue
        let logData = Data(base64Encoded: logb64, options: [])
        let logString = String(data: logData!, encoding: .utf8)!
        
        let regex = try NSRegularExpression(pattern: "REPORT RequestId: (\\S+)\\s+Duration: (\\d*\\.\\d\\d ms)\\s+Billed Duration: (\\d+ ms)\\s+Memory Size: (\\d+ MB)\\s+Max Memory Used: (\\d+ MB)", options: [])
        let extracted = logString.extractRegexFields(regex: regex)
        
        return InvokeResponse(tail: logString, elapsed: extracted[2], billed: extracted[3], memory: extracted[4], usedMemory: extracted[5])
    }
}

class LogsCommand {
    func command(tail: Bool) throws {
        _ = try logs(tail: tail)
    }
    
    // TODO: leaky because of unit testing?
    func logs(tail: Bool) throws -> String {
        let config = Template.parseTemplateAtPath(".")!

        let stackOutputs = try CloudFormation.outputs(name: config.name)
        let functionName = stackOutputs["FunctionName"]!
        let group = "/aws/lambda/\(functionName)"

        let streamNameInvocation = [
            "aws logs describe-log-streams",
            "--log-group-name \(group)",
            "--order-by LastEventTime",
            "--descending",
            "--query logStreams[0].logStreamName",
            "--output text"
            ].joined(separator: " ")
        let (stdout, _) = try ShellCommand.piped(command: streamNameInvocation, label: "log stream name")

        let stream = stdout.trimmingCharacters(in: .newlines)

        let logLinesInvocation = [
            "aws logs get-log-events",
            "--log-group-name \(group)",
            "--log-stream-name '\(stream)'",
            "--query events[*].message",
            "--output text"
            ].joined(separator: " ")
        let (logsOut, _) = try ShellCommand.piped(command: logLinesInvocation, label: "log lines fetch")
        return logsOut
    }
}

class DestroyCommand {
    func command() throws {
        let config = Template.parseTemplateAtPath(".")!
        try CloudFormation.stackDown(name: config.name)
    }
}

class SetupCommand {
    func command() throws {
        let templateURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("cloudformation-defaults.yml")!
        try FileLiterals.InitialSetup.write(to: templateURL, atomically: true, encoding: .utf8)
        _ = try ShellCommand.piped(command: "stackup swift-lambda-defaults up -t \(templateURL.path)", label: "cfn setup")
    }
}

class InitCommand {
    func command(name: String) {
        do {
            let fm = FileManager.default

            let cwdStr = fm.currentDirectoryPath
            let cwd = URL(fileURLWithPath: cwdStr, isDirectory: true)
            let dir = cwd.appendingPathComponent(name)

            try fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            try fm.createDirectory(at: dir.appendingPathComponent("Sources"), withIntermediateDirectories: true, attributes: nil)

            let packageStr = FileLiterals.InitFiles_Package.replacingOccurrences(of: "<name>", with: name)
            try packageStr.write(to: dir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

            let SwiftLambdaStr = FileLiterals.InitFiles_swift_lambda.replacingOccurrences(of: "<name>", with: name)
            try SwiftLambdaStr.write(to: dir.appendingPathComponent("swift-lambda.json"), atomically: true, encoding: .utf8)

            try FileLiterals.InitFiles_main.write(to: dir.appendingPathComponent("Sources/main.swift"), atomically: true, encoding: .utf8)
            try FileLiterals.InitFiles_dockerignore.write(to: dir.appendingPathComponent(".dockerignore"), atomically: true, encoding: .utf8)
        } catch {

        }
    }
}

public let MainCommand = Group {
    $0.command("init", Argument("name", description: "Name of new project"), InitCommand().command)

    $0.command("build", BuildCommand().command)

    $0.command("deploy", Flag("new-version", description: "Generate new version from new code"), Flag("skip-libs", description: "Skip uploading native dependencies"), DeployCommand().command)

    $0.command("logs", Flag("tail"), LogsCommand().command)

    $0.command("destroy", DestroyCommand().command)

    $0.command("setup", SetupCommand().command)

    $0.command("debug") {
        fatalError("Not implemented yet")
    }

    $0.command("invoke", Flag("async"), Flag("local"), InvokeCommand().command)
}
