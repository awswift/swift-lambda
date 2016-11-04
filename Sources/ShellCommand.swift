import Foundation

struct ShellCommand {
  static func command(command: String, stdout: @escaping (_: String) -> (), stderr: @escaping (_: String) -> ()) -> Int {
    #if os(Linux)
      let buildProcess = Task()
    #else
      let buildProcess = Process()
    #endif
    buildProcess.launchPath = "/bin/bash"
    buildProcess.arguments = ["-c", command]
    buildProcess.environment = ProcessInfo.processInfo.environment
    
    let outChunker = LineChunker { stdout($0) }
    let out = Pipe()
    
    buildProcess.standardOutput = out
    out.fileHandleForReading.readabilityHandler = { handle in
      let str = String(data: handle.availableData, encoding: .utf8)!
      outChunker.append(str)
      
    }
    
    let errChunker = LineChunker { stderr($0) }
    let err = Pipe()
    
    buildProcess.standardError = err
    err.fileHandleForReading.readabilityHandler = { handle in
      let str = String(data: handle.availableData, encoding: .utf8)!
      errChunker.append(str)
    }
    
    buildProcess.terminationHandler = { task in
      if let line = outChunker.remainder() { stdout(line) }
      if let line = errChunker.remainder() { stderr(line) }
      
      out.fileHandleForReading.readabilityHandler = nil
      err.fileHandleForReading.readabilityHandler = nil
    }
    
    buildProcess.launch()
    buildProcess.waitUntilExit()
    return Int(buildProcess.terminationStatus)
  }
  
  static func piped(command: String, label: String?) -> (Int, String, String) {
    let prefix = label ?? command
    var stdout = String()
    var stderr = String()
    
    if label != nil {
      print("\(label!): ".green + command.bold.green)
    }
    
    let exitCode = ShellCommand.command(command: command, stdout: { line in
      print("\(prefix): ".green + line)
      stdout.append(line + "\n")
    }, stderr: { line in
      print("\(prefix): ".red + line)
      stderr.append(line + "\n")
    })
    
    return (exitCode, stdout, stderr)
  }
}
