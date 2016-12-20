import Foundation
import Commander
import Rainbow
import SwiftyJSON

func packageInfo() -> [String: Any] {
    let (_, stdout, _) = ShellCommand.piped(command: "swift package dump-package", label: "pkg info")
    return try! JSONSerialization.jsonObject(with: stdout.data(using: .utf8)!, options: []) as! [String: Any]
}

var config = Template.parseTemplateAtPath(".")!

func dockerfile() -> String {
    let packageName = packageInfo()["name"] as! String
    
    return [
        "FROM awswift/swiftda",
        "WORKDIR /app",
        "COPY Package.swift .",
        "RUN swift package fetch",
        "COPY . .",
        "RUN swift build",
        "WORKDIR .build/debug",
        "RUN cp /usr/lib/swift/linux/*.so* .",
        "RUN cp ../../.swiftda/index.js .",
        "RUN mv \(packageName) swiftdaEntrypoint",
        "RUN zip /app/lambda.zip swiftdaEntrypoint *.so* index.js"
        ].joined(separator: "\n")
}

class BuildCommand {
    func command() {
        let packageName = packageInfo()["name"] as! String
        
        _ = ShellCommand.piped(command: "mkdir -p .swiftda", label: nil)
        
        let dockerfilePath = ".swiftda/Dockerfile"
        try! dockerfile().write(toFile: dockerfilePath, atomically: true, encoding: .utf8)
        try! FileLiterals.index.write(toFile: ".swiftda/index.js", atomically: true, encoding: .utf8)
        
        let imageId = "swiftda-builder-\(packageName):\(arc4random())"
        let containerId = "swiftda-\(packageName)-\(arc4random())"
        //    _ = ShellCommand.piped(command: "docker pull swiftda", label: "🐳 pull")
        _ = ShellCommand.piped(command: "docker build -f \(dockerfilePath) -t \(imageId) .", label: "🐳 build")
        _ = ShellCommand.piped(command: "docker run -i --name \(containerId) \(imageId) true", label: "🐳 container")
        _ = ShellCommand.piped(command: "docker cp \(containerId):/app/lambda.zip \(packageName).lambda.zip", label: "copy zip")
    }
}

struct CloudFormation {
    /*
     enum StackStatus: String {
     case CREATE_IN_PROGRESS = "CREATE_IN_PROGRESS"
     case CREATE_FAILED = "CREATE_FAILED"
     case CREATE_COMPLETE = "CREATE_COMPLETE"
     case ROLLBACK_IN_PROGRESS = "ROLLBACK_IN_PROGRESS"
     case ROLLBACK_FAILED = "ROLLBACK_FAILED"
     case ROLLBACK_COMPLETE = "ROLLBACK_COMPLETE"
     case DELETE_IN_PROGRESS = "DELETE_IN_PROGRESS"
     case DELETE_FAILED = "DELETE_FAILED"
     case DELETE_COMPLETE = "DELETE_COMPLETE"
     case UPDATE_IN_PROGRESS = "UPDATE_IN_PROGRESS"
     case UPDATE_COMPLETE_CLEANUP_IN_PROGRESS = "UPDATE_COMPLETE_CLEANUP_IN_PROGRESS"
     case UPDATE_COMPLETE = "UPDATE_COMPLETE"
     case UPDATE_ROLLBACK_IN_PROGRESS = "UPDATE_ROLLBACK_IN_PROGRESS"
     case UPDATE_ROLLBACK_FAILED = "UPDATE_ROLLBACK_FAILED"
     case UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS = "UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS"
     case UPDATE_ROLLBACK_COMPLETE = "UPDATE_ROLLBACK_COMPLETE"
     case REVIEW_IN_PROGRESS = "REVIEW_IN_PROGRESS"
     
     case NO_SUCH_STACK = "SWIFTDA_NO_SUCH_STACK"
     }
     
     static func stackStatus(_ name: String) -> StackStatus {
     let (ec, stdout, _) = ShellCommand.piped(command: "aws cloudformation describe-stacks --stack-name \(name) --query Stacks[0].StackStatus --output text", label: "cfn check")
     let statusStr = stdout.trimmingCharacters(in: .newlines)
     
     if ec > 0 {
     return .NO_SUCH_STACK
     } else if let status = StackStatus(rawValue: statusStr) {
     return status
     } else {
     fatalError()
     }
     }
     
     static func stackAction(action: String, name: String, template: URL, parameters: [String: String]) {
     let parametersStr = parameters.reduce("") { result, tuple in
     return "\(result) ParameterKey=\(tuple.key),ParameterValue=\(tuple.value)"
     }
     
     let invocation = [
     "aws cloudformation \(action)",
     "--stack-name \(name)",
     "--parameters \(parametersStr)",
     "--template-body \(template.absoluteString)",
     "--tags Key=SwiftdaVer,Value=0.1"
     ].joined(separator: " ")
     
     _ = ShellCommand.piped(command: invocation, label: "cfn \(action)")
     }
     
     static func stackUp(name: String, template: URL, parameters: [String: String]) {
     let status = stackStatus(name)
     let action: String
     
     if case .NO_SUCH_STACK = status {
     action = "create-stack"
     } else {
     action = "update-stack"
     }
     
     stackAction(action: action, name: name, template: template, parameters: parameters)
     }
     */
    static func stackUp(name: String, template: URL, parameters: [String: String]) {
        let paramStr = parameters.reduce("") { result, tuple in "\(result) -o \(tuple.key)=\(tuple.value)" }
        _ = ShellCommand.piped(command: "stackup \(name) up -t \(template.path) \(paramStr)", label: "cfn up")
    }
    
    static func stackDown(name: String) {
        _ = ShellCommand.piped(command: "stackup \(name) down", label: "cfn down")
    }
    
    static func outputs(name: String) -> [String: String] {
        let (_, stdout, _) = ShellCommand.piped(command: "aws cloudformation describe-stacks --stack-name \(name) --query Stacks[0].Outputs", label: "cfn outputs")
        let json = JSON(data: stdout.data(using: .utf8)!)
        var outputs: [String: String] = [:]
        json.arrayValue.forEach { outputs[$0["OutputKey"].stringValue] = $0["OutputValue"].stringValue }
        return outputs
    }
    
    static func exports() -> [String: String] {
        let (_, stdout, _) = ShellCommand.piped(command: "aws cloudformation list-exports", label: "cfn vals")
        let exportsJson = JSON(data: stdout.data(using: .utf8)!)["Exports"].arrayValue
        var exports: [String: String] = [:]
        exportsJson.forEach { exports[$0["Name"].stringValue] = $0["Value"].stringValue }
        return exports
    }
}

class DeployCommand {
    func command(newVersion: Bool) {
        let zipUrl = URL(string: "\(config.name).lambda.zip", relativeTo: config.url)!
        let zipPath = zipUrl.path
        
        guard FileManager.default.fileExists(atPath: zipPath) else {
            return
        }
        
        _ = ShellCommand.piped(command: "aws s3 cp \(zipPath) s3://\(config.bucket)/\(config.key)", label: "s3 cp")
        let (_, s3stdout, _) = ShellCommand.piped(command: "aws s3api head-object --bucket \(config.bucket) --key \(config.key) --query VersionId --output text", label: "s3 ver")
        let s3version = s3stdout.trimmingCharacters(in: .newlines)
        
        let params = [
            "S3Bucket": config.bucket,
            "S3Key": config.key,
            "S3ObjectVersion": s3version,
            "Role": config.role
        ]
        
        let templateURL = URL(fileURLWithPath: ".swiftda/cloudformation.yml")
        try! FileLiterals.CloudFormation.write(to: templateURL, atomically: true, encoding: .utf8)
        CloudFormation.stackUp(name: config.name, template: templateURL, parameters: params)
    }
}

class InvokeCommand {
    func command(async: Bool, local: Bool) {
        if async || local {
            fatalError("Not implemented yet")
        }
        
        let stackOutputs = CloudFormation.outputs(name: config.name)
        let functionName = stackOutputs["FunctionName"]!
        
        let (_, stdout, _) = ShellCommand.piped(command: "aws lambda invoke --function-name \(functionName) --log-type Tail /dev/null", label: "ƛ invoke")
        let json = JSON(data: stdout.data(using: .utf8)!)
        let logb64 = json["LogResult"].stringValue
        let logData = Data(base64Encoded: logb64, options: [])
        let log = String(data: logData!, encoding: .utf8)!
        print(log)
    }
}

class LogsCommand {
    func command(tail: Bool) {
        let stackOutputs = CloudFormation.outputs(name: config.name)
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
        let (_, stdout, _) = ShellCommand.piped(command: streamNameInvocation, label: "log stream name")
        
        let stream = stdout.trimmingCharacters(in: .newlines)
        
        let logLinesInvocation = [
            "aws logs get-log-events",
            "--log-group-name \(group)",
            "--log-stream-name '\(stream)'",
            "--query events[*].message",
            "--output text"
            ].joined(separator: " ")
        _ = ShellCommand.piped(command: logLinesInvocation, label: "log lines fetch")
    }
}

class DestroyCommand {
    func command() {
        CloudFormation.stackDown(name: config.name)
    }
}

class SetupCommand {
    func command() {
        let templateURL = URL(fileURLWithPath: ".swiftda/cloudformation-defaults.yml")
        try! FileLiterals.InitialSetup.write(to: templateURL, atomically: true, encoding: .utf8)
        _ = ShellCommand.piped(command: "stackup swiftda-defaults up -t \(templateURL.path)", label: "cfn setup")
    }
}

let main = Group {
    $0.command("init", Argument("name", description: "Name of new project")) { (name: String) in
        fatalError("Not implemented yet")
    }
    
    $0.command("build", BuildCommand().command)
    
    $0.command("deploy", Flag("new-version", description: "Generate new version from new code"), DeployCommand().command)
    
    $0.command("logs", Flag("tail"), LogsCommand().command)
    
    $0.command("destroy", DestroyCommand().command)
    
    $0.command("setup", SetupCommand().command)
    
    $0.command("debug") {
        fatalError("Not implemented yet")
    }
    
    $0.command("invoke", Flag("async"), Flag("local"), InvokeCommand().command)
}

main.run()
