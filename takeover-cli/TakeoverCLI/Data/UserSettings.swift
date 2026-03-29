//
//  UserSettings.swift
//  TakeoverCLI
//
//  Created by Alex Vaos on 1/20/26.
//

import Foundation
import Yams

struct AppSetting: Codable {
    let name: String
    let enabled: Bool
}

struct Settings: Codable {
    let apps: [AppSetting]
}

class UserSettings {

    static let filePath = "user_settings.yml"

    static func load() throws -> Settings {
        let fileURL = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: fileURL)
        let settings: Settings = try YAMLDecoder().decode(Settings.self, from: data)
        return settings
    }

    static func save(_ settings: Settings) throws {
        let fileURL = URL(fileURLWithPath: filePath)
        let yamlData = try YAMLEncoder().encode(settings)
        try yamlData.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    // Helper method to check if an app is enabled
    static func isEnabled(_ appName: String, in settings: Settings) -> Bool {
        return settings.apps.first(where: { $0.name.lowercased() == appName.lowercased() })?.enabled ?? false
    }

    // Helper method to update an app's enabled status
    static func updateApp(_ appName: String, enabled: Bool, in settings: Settings) -> Settings {
        let updatedApps = settings.apps.map { app in
            if app.name.lowercased() == appName.lowercased() {
                return AppSetting(name: app.name, enabled: enabled)
            }
            return app
        }
        return Settings(apps: updatedApps)
    }
}