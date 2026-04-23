//
//  TakeoverApp.swift
//  Takeover
//
//  Created by Alex Vaos on 2/12/25.
//

import SwiftUI
import SwiftData

@main
struct TakeoverApp: App {
    @StateObject private var settingsManager = SettingsManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LinkItem.self,
            MacDefault.self,
            AppInstaller.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await checkPermissionsOnStartup()
                    await ensureICloudDirectoryExists()
                    await loadSettingsAndPopulate()
                    await Repository.shared.load()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func checkPermissionsOnStartup() async {
        if !PermissionsHelper.hasFullDiskAccess() {
            print("⚠️ Full Disk Access not granted")
            PermissionsHelper.showFullDiskAccessAlert()
        } else {
            print("✅ Full Disk Access granted")
        }
    }

    private func ensureICloudDirectoryExists() async {
        let iCloudPath = Config.expandedBackupPath

        print("DEBUG: Checking iCloud directory at: \(iCloudPath)")

        // Use shell command to check if directory exists
        let escapedPath = iCloudPath.replacingOccurrences(of: "'", with: "'\\''")
        let checkCommand = "test -d '\(escapedPath)' && echo 'exists' || echo 'not_exists'"
        let checkResult = Linker.shell(checkCommand).trimmingCharacters(in: .whitespacesAndNewlines)

        if checkResult == "not_exists" {
            // Directory doesn't exist, create it using osascript (has proper permissions)
            let escapedPathForOsascript = iCloudPath.replacingOccurrences(of: "\"", with: "\\\"")
            let createDirScript = "do shell script \"mkdir -p \\\"\(escapedPathForOsascript)\\\"\""
            print("DEBUG: Creating directory with osascript")
            let createResult = Linker.shell("osascript -e '\(createDirScript)'")

            if createResult.isEmpty {
                print("Created iCloud Takeover directory at: \(iCloudPath)")
            } else {
                print("DEBUG: osascript result: \(createResult)")
            }
        } else {
            print("DEBUG: iCloud directory already exists at: \(iCloudPath)")
        }
    }

    private func loadSettingsAndPopulate() async {
        do {
            let settings = try await settingsManager.loadSettings()
            try await MacDefaultCatalog.shared.loadOrCreate()
            await syncSettingsToDatabase(settings: settings)
        } catch {
            print("Error loading settings: \(error)")
        }
    }

    @MainActor
    private func syncSettingsToDatabase(settings: SettingsYaml) async {
        let context = sharedModelContainer.mainContext

        // Sync LinkItems
        let descriptor = FetchDescriptor<LinkItem>()
        let existingItems = (try? context.fetch(descriptor)) ?? []
        let existingNames = Set(existingItems.map { $0.name })

        for linkConfig in settings.links {
            if !existingNames.contains(linkConfig.name) {
                let newItem = LinkItem(
                    name: linkConfig.name,
                    from: expandTilde(linkConfig.from),
                    to: expandTilde(linkConfig.to),
                    defaults: linkConfig.defaults ?? ""
                )
                context.insert(newItem)
            }
        }

        // Sync MacDefaults: catalog is source of metadata, user settings supply values
        let defaultsDescriptor = FetchDescriptor<MacDefault>()
        let existingDefaults = (try? context.fetch(defaultsDescriptor)) ?? []
        let existingDefaultNames = Set(existingDefaults.map { $0.name })

        let userValues: [String: String] = Dictionary(
            uniqueKeysWithValues: (settings.macDefaults ?? []).compactMap { config in
                guard let v = config.value, !v.isEmpty else { return nil }
                return (config.name, v)
            }
        )

        for entry in MacDefaultCatalog.shared.entries {
            if !existingDefaultNames.contains(entry.name) {
                context.insert(MacDefault(
                    name: entry.name,
                    domain: entry.domain,
                    key: entry.key,
                    type: entry.type,
                    value: userValues[entry.name] ?? "",
                    hostFlag: entry.hostFlag ?? "",
                    postCommand: entry.postCommand ?? ""
                ))
            }
        }

        // Sync AppInstallers
        let installersDescriptor = FetchDescriptor<AppInstaller>()
        let existingInstallers = (try? context.fetch(installersDescriptor)) ?? []
        let existingInstallerNames = Set(existingInstallers.map { $0.name })

        for config in settings.appInstallers ?? [] {
            if !existingInstallerNames.contains(config.name) {
                context.insert(AppInstaller(name: config.name, path: expandTilde(config.path)))
            }
        }

        try? context.save()
    }

    private func expandTilde(_ path: String) -> String {
        return PathUtility.expandTildeToRealHome(path)
    }
}
