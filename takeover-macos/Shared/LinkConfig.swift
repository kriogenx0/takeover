import Foundation

struct LinkConfig: Codable {
    var name: String
    var from: String
    var to: String
    var defaults: String?
}

struct MacDefaultConfig: Codable {
    var name: String
    var value: String?
    var capturedOSMajorVersion: Int?

    enum CodingKeys: String, CodingKey {
        case name, value
        case capturedOSMajorVersion = "captured_os_major_version"
    }
}

struct AppInstallerConfig: Codable {
    var name: String
    var path: String
}
