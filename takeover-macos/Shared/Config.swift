import Foundation

struct Config {
    static let backupPath = "~/Library/Application Support/Takeover"

    static var expandedBackupPath: String {
        PathUtility.expandTildeToRealHome(backupPath)
    }

    static var settingsPath: String {
        "\(expandedBackupPath)/takeover-settings.yaml"
    }
}
