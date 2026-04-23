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
}

struct AppInstallerConfig: Codable {
    var name: String
    var path: String
}
