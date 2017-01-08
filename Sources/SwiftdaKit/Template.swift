import Foundation
import SwiftyJSON

struct Template {
    let json: JSON
    let url: URL
    let defaults: [String: String]

    static func configURL(_ path: String) -> URL? {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else {
            return nil
        }

        let configPath: String
        if isDir.boolValue {
            configPath = (path as NSString).appendingPathComponent("Swiftda.json")
        } else {
            configPath = path
        }
        return URL(fileURLWithPath: configPath).absoluteURL
    }

    static func parseTemplateAtPath(_ path: String) -> Template? {
        guard let url = configURL(path) else {
            return nil
        }

        let raw = try! Data(contentsOf: url)
        let json = JSON(data: raw)

        let defaults = try! CloudFormation.exports()

        if json["AWSTemplateFormatVersion"].string != nil {
            return Template(json: json, url: url, defaults: defaults)
        } else {
            let data = FileLiterals.CloudFormation.data(using: .utf8)!
            var base = JSON(data: data)
            base["Metadata"] = json
            return Template(json: base, url: url, defaults: defaults)
        }
    }

    var name: String {
        return json["Metadata"]["Name"].stringValue
    }

    var role: String {
        return json["Metadata"]["Role"].string ?? defaults["SwiftdaExecutionRoleArn"]!
    }

    var bucket: String {
        return json["Metadata"]["Bucket"].string ?? defaults["SwiftdaCodeStorageBucket"]!
    }

    var key: String {
        return json["Metadata"]["Key"].string ?? "\(name).zip"
    }

    var description: String {
        return json["Metadata"]["Description"].stringValue
    }

    var memory: String {
        return json["Metadata"]["Memory"].stringValue
    }

    var timeout: String {
        return json["Metadata"]["Timeout"].stringValue
    }
    
    var yumDependencies: [String] {
        return (json["Metadata"]["YumDependencies"].array ?? []).map { $0.stringValue }
    }

    func write(to url: URL) {
        let data = try! json.rawData(options: .prettyPrinted)
        try! data.write(to: url, options: .atomic)
    }
}
