import Foundation

struct ShellCommand {
    static func command(command: String, stdout: @escaping (_: String) -> Void, stderr: @escaping (_: String) -> Void) -> Int {
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

        let queue = DispatchQueue(label: "swiftda.shellcommand.queue")
        let sema = DispatchSemaphore(value: 0)

        buildProcess.standardOutput = out
        out.fileHandleForReading.readabilityHandler = { handle in
            let str = String(data: handle.availableData, encoding: .utf8)!
            queue.async {
                outChunker.append(str)
            }
        }

        let errChunker = LineChunker { stderr($0) }
        let err = Pipe()

        buildProcess.standardError = err
        err.fileHandleForReading.readabilityHandler = { handle in
            let str = String(data: handle.availableData, encoding: .utf8)!
            queue.async {
                errChunker.append(str)
            }
        }

        buildProcess.terminationHandler = { task in
            queue.async {
                if let line = outChunker.remainder() { stdout(line) }
                if let line = errChunker.remainder() { stderr(line) }

                out.fileHandleForReading.readabilityHandler = nil
                err.fileHandleForReading.readabilityHandler = nil
                sema.signal()
            }
        }

        buildProcess.launch()
        buildProcess.waitUntilExit()
        sema.wait()
        return Int(buildProcess.terminationStatus)
    }
    
    struct Redir: TextOutputStream {
        mutating func write(_ string: String) {
            FileHandle.standardError.write(string.data(using: .utf8)!)
        }
    }

    static func piped(command: String, label: String?) -> (Int, String, String) {
        let prefix = label ?? command
        var stdout = String()
        var stderr = String()
        
        var redir = Redir()
        
        if label != nil {
            print("\(label!): ".green + command.bold.green)
        }

        let exitCode = ShellCommand.command(command: command, stdout: { line in
            print("\(prefix): ".green + line, to: &redir)
            stdout.append(line + "\n")
        }, stderr: { line in
            print("\(prefix): ".red + line, to: &redir)
            stderr.append(line + "\n")
        })

        return (exitCode, stdout, stderr)
    }
}
