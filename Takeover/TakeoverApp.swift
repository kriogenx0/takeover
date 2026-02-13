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
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func checkPermissionsOnStartup() async {
        // Check if app has Full Disk Access
        if !PermissionsHelper.hasFullDiskAccess() {
            print("⚠️ Full Disk Access not granted")
            print("The app will prompt for permissions when you try to install a link")
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
            await syncSettingsToDatabase(settings: settings)
        } catch {
            print("Error loading settings: \(error)")
        }
    }

    @MainActor
    private func syncSettingsToDatabase(settings: SettingsYaml) async {
        let context = sharedModelContainer.mainContext

        // Fetch existing items
        let descriptor = FetchDescriptor<LinkItem>()
        let existingItems = (try? context.fetch(descriptor)) ?? []

        // Create a set of existing names for quick lookup
        let existingNames = Set(existingItems.map { $0.name })

        // Add new items from YAML that don't exist in database
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

        try? context.save()
    }

    private func expandTilde(_ path: String) -> String {
        return PathUtility.expandTildeToRealHome(path)
    }
}
