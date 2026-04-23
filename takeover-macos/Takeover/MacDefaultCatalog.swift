import Foundation
import Yams

struct MacDefaultCatalogEntry: Codable {
    let name: String
    let domain: String
    let key: String
    let type: String
    let hostFlag: String?
    let postCommand: String?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case name, domain, key, type, category
        case hostFlag = "host_flag"
        case postCommand = "post_command"
    }
}

class MacDefaultCatalog {
    static let shared = MacDefaultCatalog()
    private(set) var entries: [MacDefaultCatalogEntry] = []

    private init() {}

    var catalogFileURL: URL {
        SettingsManager.shared.settingsFileURL
            .deletingLastPathComponent()
            .appendingPathComponent("mac-defaults-catalog.yaml")
    }

    func loadOrCreate() async throws {
        let url = catalogFileURL
        if !FileManager.default.fileExists(atPath: url.path) {
            try copyBundledCatalog(to: url)
        }
        let data = try Data(contentsOf: url)
        let yaml = String(data: data, encoding: .utf8) ?? ""
        entries = try YAMLDecoder().decode([MacDefaultCatalogEntry].self, from: yaml)
    }

    private func copyBundledCatalog(to url: URL) throws {
        guard let bundleURL = Bundle.main.url(forResource: "mac-defaults-catalog", withExtension: "yaml") else {
            throw CatalogError.bundleResourceNotFound
        }
        try FileManager.default.copyItem(at: bundleURL, to: url)
    }
}

enum CatalogError: Error {
    case bundleResourceNotFound
}
