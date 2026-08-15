import Foundation
import CoreFoundation

func normalized(_ value: Any?) -> Any {
    guard let value else { return NSNull() }
    if let text = value as? String { return text }
    if let number = value as? NSNumber { return number }
    if let date = value as? Date { return ISO8601DateFormatter().string(from: date) }
    if let data = value as? Data { return data.base64EncodedString() }
    if let array = value as? [Any] { return array.map(normalized) }
    if let dictionary = value as? [String: Any] {
        return Dictionary(uniqueKeysWithValues: dictionary.map { ($0.key, normalized($0.value)) })
    }
    return String(describing: value)
}

func stringFromCF(_ value: CFString?) -> Any {
    guard let value else { return NSNull() }
    return value as String
}

guard CommandLine.arguments.count == 4 else {
    fputs("usage: BundleProbe <label> <app-path> <output-json>\n", stderr)
    exit(2)
}

let label = CommandLine.arguments[1]
let appURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[3])
var result: [String: Any] = [
    "label": label,
    "inputURL": appURL.path,
]

if let bundle = Bundle(url: appURL) {
    result["foundationBundleCreated"] = true
    result["foundationBundleURL"] = bundle.bundleURL.path
    result["foundationBundleIdentifier"] = bundle.bundleIdentifier ?? NSNull()
    result["foundationExecutableURL"] = bundle.executableURL?.path ?? NSNull()
    result["foundationResourceURL"] = bundle.resourceURL?.path ?? NSNull()
    result["foundationCFBundleIdentifierObject"] = normalized(bundle.object(forInfoDictionaryKey: "CFBundleIdentifier"))
    result["foundationCFBundleExecutableObject"] = normalized(bundle.object(forInfoDictionaryKey: "CFBundleExecutable"))
    result["foundationInfoDictionary"] = normalized(bundle.infoDictionary)
} else {
    result["foundationBundleCreated"] = false
    result["foundationBundleIdentifier"] = NSNull()
    result["foundationExecutableURL"] = NSNull()
}

if let cfBundle = CFBundleCreate(kCFAllocatorDefault, appURL as CFURL) {
    result["cfBundleCreated"] = true
    result["cfBundleIdentifier"] = stringFromCF(CFBundleGetIdentifier(cfBundle))
    result["cfBundleExecutableURL"] = (CFBundleCopyExecutableURL(cfBundle) as URL?)?.path ?? NSNull()
    result["cfBundleInfoDictionary"] = normalized(CFBundleGetInfoDictionary(cfBundle) as NSDictionary)
} else {
    result["cfBundleCreated"] = false
    result["cfBundleIdentifier"] = NSNull()
    result["cfBundleExecutableURL"] = NSNull()
}

let json = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
try json.write(to: outputURL)
