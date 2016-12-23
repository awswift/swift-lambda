import Foundation

let inputData = FileHandle.standardInput.readDataToEndOfFile()
let json = try! JSONSerialization.jsonObject(with: inputData, options: []) as! [String: Any]

var copy = json
copy["output"] = "Hello, world!"

let outputData = try! JSONSerialization.data(withJSONObject: copy, options: [])
FileHandle.standardOutput.write(outputData)
