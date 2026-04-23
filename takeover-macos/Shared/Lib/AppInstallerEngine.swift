import Foundation

enum AppFileType {
    case zip, dmg, app, pkg

    var systemImage: String {
        switch self {
        case .zip: return "archivebox"
        case .dmg: return "opticaldiscdrive"
        case .app: return "app.badge"
        case .pkg: return "shippingbox"
        }
    }

    var label: String {
        switch self {
        case .zip: return "ZIP"
        case .dmg: return "DMG"
        case .app: return "APP"
        case .pkg: return "PKG"
        }
    }
}

struct DiscoveredApp: Identifiable {
    var id: String { fileURL.path }
    var name: String
    var fileURL: URL
    var fileType: AppFileType

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: "/Applications/\(name).app")
    }
}

struct AppInstallerEngine {

    static func scan(at path: String) -> [DiscoveredApp] {
        let expanded = PathUtility.expandTildeToRealHome(path)
        let dirURL = URL(fileURLWithPath: expanded)

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dirURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { url in
                let ext = url.pathExtension.lowercased()
                let baseName = url.deletingPathExtension().lastPathComponent
                switch ext {
                case "zip": return DiscoveredApp(name: baseName, fileURL: url, fileType: .zip)
                case "dmg": return DiscoveredApp(name: baseName, fileURL: url, fileType: .dmg)
                case "app": return DiscoveredApp(name: baseName, fileURL: url, fileType: .app)
                case "pkg": return DiscoveredApp(name: baseName, fileURL: url, fileType: .pkg)
                default: return nil
                }
            }
    }

    static func install(_ app: DiscoveredApp) -> (success: Bool, message: String) {
        switch app.fileType {
        case .zip: return installZip(app)
        case .dmg: return installDmg(app)
        case .app: return copyApp(from: app.fileURL)
        case .pkg: return installPkg(app)
        }
    }

    private static func installZip(_ app: DiscoveredApp) -> (Bool, String) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("takeover-\(UUID().uuidString)")

        let unzipResult = Linker.shell("ditto -xk '\(app.fileURL.path)' '\(tempDir.path)'")
        guard !unzipResult.lowercased().contains("error") else {
            return (false, "Unzip failed: \(unzipResult)")
        }

        guard let appURL = findApp(in: tempDir) else {
            Linker.shell("rm -rf '\(tempDir.path)'")
            return (false, "No .app found in zip")
        }

        let result = copyApp(from: appURL)
        Linker.shell("rm -rf '\(tempDir.path)'")
        return result
    }

    private static func installDmg(_ app: DiscoveredApp) -> (Bool, String) {
        let attachOutput = Linker.shell("hdiutil attach '\(app.fileURL.path)' -nobrowse -quiet -plist")

        let mountPoint = parseMountPoint(from: attachOutput)
        guard let mountPath = mountPoint else {
            return (false, "Could not mount DMG")
        }

        let mountURL = URL(fileURLWithPath: mountPath)
        guard let appURL = findApp(in: mountURL) else {
            Linker.shell("hdiutil detach '\(mountPath)' -quiet")
            return (false, "No .app found in DMG")
        }

        let result = copyApp(from: appURL)
        Linker.shell("hdiutil detach '\(mountPath)' -quiet")
        return result
    }

    private static func installPkg(_ app: DiscoveredApp) -> (Bool, String) {
        let escapedPath = app.fileURL.path.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"installer -pkg '\\\"'\(escapedPath)'\\\"' -target /\" with administrator privileges"
        let output = Linker.shell("osascript -e '\(script)'")
        let failed = output.lowercased().contains("failed") || output.lowercased().contains("error")
        return (!failed, failed ? "Install failed: \(output.trimmingCharacters(in: .whitespacesAndNewlines))" : "Installed \(app.name)")
    }

    private static func copyApp(from appURL: URL) -> (Bool, String) {
        let appName = appURL.lastPathComponent
        let destPath = "/Applications/\(appName)"
        let escapedSrc = appURL.path.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedDst = destPath.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"ditto '\\\"'\(escapedSrc)'\\\"' '\\\"'\(escapedDst)'\\\"'\" with administrator privileges"
        Linker.shell("osascript -e '\(script)'")
        let success = FileManager.default.fileExists(atPath: destPath)
        return (success, success ? "Installed \(appName)" : "Installation failed")
    }

    private static func findApp(in directory: URL) -> URL? {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        if let direct = contents.first(where: { $0.pathExtension.lowercased() == "app" }) {
            return direct
        }

        for item in contents {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDir, let found = findApp(in: item) { return found }
        }

        return nil
    }

    // Parse the mount point from hdiutil -plist output
    private static func parseMountPoint(from output: String) -> String? {
        guard let data = output.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let entities = plist["system-entities"] as? [[String: Any]] else {
            // Fallback: parse tab-delimited output
            return output.components(separatedBy: "\n").compactMap { line -> String? in
                let parts = line.components(separatedBy: "\t")
                let point = parts.last?.trimmingCharacters(in: .whitespaces) ?? ""
                return point.hasPrefix("/Volumes/") ? point : nil
            }.first
        }

        return entities.compactMap { $0["mount-point"] as? String }
            .first { $0.hasPrefix("/Volumes/") }
    }
}
