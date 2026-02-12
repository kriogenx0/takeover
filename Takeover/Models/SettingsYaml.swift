//
//  SettingsYaml.swift
//  Takeover
//
//  Created by Alex Vaos on 11/4/25.
//

import Foundation
import Yams

struct SettingsYaml: Codable {
    var links: [LinkConfig]

    struct LinkConfig: Codable {
        var name: String
        var from: String
        var to: String
        var defaults: String?
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    @Published var settings: SettingsYaml?
    @Published var usingICloud: Bool = false

    private let fileName = "takeover-settings.yaml"

    private init() {}

    var iCloudDocumentsURL: URL? {
        // Use hardcoded iCloud Drive path (doesn't require entitlements)
        let url = URL(fileURLWithPath: Config.expandedBackupPath)

        // Check if iCloud Drive exists and is accessible
        var isDirectory: ObjCBool = false
        let parentExists = FileManager.default.fileExists(atPath: (url.deletingLastPathComponent().path), isDirectory: &isDirectory)

        return parentExists ? url : nil
    }

    var localDocumentsURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Takeover")
    }

    var settingsFileURL: URL {
        // Try iCloud first, fall back to local
        if let iCloudURL = iCloudDocumentsURL {
            return iCloudURL.appendingPathComponent(fileName)
        } else {
            return localDocumentsURL.appendingPathComponent(fileName)
        }
    }

    func loadSettings() async throws -> SettingsYaml {
        let fileURL = settingsFileURL

        // Determine if we're using iCloud
        await MainActor.run {
            self.usingICloud = iCloudDocumentsURL != nil
        }

        // Create directory if it doesn't exist
        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        // Check if file exists, if not create a default one
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try createDefaultSettings(at: fileURL)
            print("Created default settings at: \(fileURL.path)")
            print("Using iCloud: \(usingICloud)")
        }

        let data = try Data(contentsOf: fileURL)
        let yamlString = String(data: data, encoding: .utf8) ?? ""

        let decoder = YAMLDecoder()
        let settings = try decoder.decode(SettingsYaml.self, from: yamlString)

        await MainActor.run {
            self.settings = settings
        }

        return settings
    }

    func saveSettings(_ settings: SettingsYaml) async throws {
        let fileURL = settingsFileURL

        let encoder = YAMLEncoder()
        let yamlString = try encoder.encode(settings)

        try yamlString.write(to: fileURL, atomically: true, encoding: .utf8)

        await MainActor.run {
            self.settings = settings
        }
    }

    private func createDefaultSettings(at url: URL) throws {
        let defaultSettings = """
        links:
          - name: "Example - Fonts"
            from: "~/Library/Fonts"
            to: "~/Documents/Takeover/Fonts"
          - name: "Example - Audio Plugins"
            from: "~/Library/Audio/Plug-Ins"
            to: "~/Documents/Takeover/AudioPlugins"
        """

        try defaultSettings.write(to: url, atomically: true, encoding: .utf8)
    }
}

enum SettingsError: Error {
    case iCloudNotAvailable
    case fileNotFound
    case invalidYAML
}