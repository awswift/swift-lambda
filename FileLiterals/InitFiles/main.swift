import Foundation
import SwiftdaRuntime

SwiftdaRuntime().run { event, context, callback in
    let name = event["name"] ?? "World" 
    callback(["output": "Hello, \(name)"])
}
