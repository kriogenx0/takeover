import Foundation

struct Config {
    static let backupBasePath = "~/Library/Application Support/Takeover"

    static var expandedBackupPath: String {
        PathUtility.expandTilde(backupBasePath)
    }

    static var settingsPath: String {
        "\(expandedBackupPath)/takeover-settings.yaml"
    }
}
