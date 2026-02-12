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
                    await loadSettingsAndPopulate()
                }
        }
        .modelContainer(sharedModelContainer)
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
                    to: expandTilde(linkConfig.to)
                )
                context.insert(newItem)
            }
        }

        try? context.save()
    }

    private func expandTilde(_ path: String) -> String {
        if path.hasPrefix("~") {
            return NSString(string: path).expandingTildeInPath
        }
        return path
    }
}
