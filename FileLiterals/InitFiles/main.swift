import Foundation
import SwiftLambdaRuntime

SwiftLambdaRuntime().run { event, context, callback in
    let name = event["name"] ?? "World" 
    callback(["output": "Hello, \(name)"])
}
