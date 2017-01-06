import Foundation
import SwiftdaRuntime

SwiftdaRuntime.run { event, context in
    let name = event["name"] ?? "World" 
    return ["output": "Hello, \(name)"]
}
