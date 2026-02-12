//
//  LinkItemList.swift
//  Takeover
//
//  Created by Alex Vaos on 3/4/25.
//

import Foundation
import SwiftUI
import SwiftData

struct LinkItemListView: View {
    
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \LinkItem.name) private var linkItems: [LinkItem] // Use @Query to fetch data
    //    var linkItems: [LinkItem] = []
//    @Binding var linkItems: [LinkItem]
    @State private var linkItemSelection: LinkItem? = nil
    @State private var showRecipesView = false
    @State private var showConflictAlert = false
    @State private var conflictLinkItem: LinkItem?
    @State private var conflictFromPath: String = ""
    @State private var conflictToPath: String = ""

    var body: some View {
        NavigationSplitView {
            if linkItems.count > 0 {
                List(selection: $linkItemSelection) {
                    ForEach(linkItems, id: \.self) { linkItem in
                        Text(linkItem.name)
                            .tag(linkItem)
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(SidebarListStyle())
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
                .onAppear {
                    // Auto-select first item if nothing is selected and items exist
                    if linkItemSelection == nil && !linkItems.isEmpty {
                        linkItemSelection = linkItems.first
                    }
                }
            } else {
                Text("No Link Items")
            }
        } detail: {
            if let selectedItem = linkItemSelection {
                LinkItemDetailView(
                    linkItem: selectedItem,
                    onSave: onSave,
                    onRun: onRun,
                    onDelete: onDelete,
                    onUninstall: onUninstall
                )
            } else {
                Text("No Link Items")
                    .foregroundColor(.secondary)
            }
        }.toolbar(content: {
            ToolbarItem(placement: .automatic) {
                Button(action: { showRecipesView = true }) {
                    Label("Browse Recipes", systemImage: "books.vertical")
                }
                .help("Browse available app configurations")
            }
            ToolbarItem(placement: .automatic) {
                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        })
        .sheet(isPresented: $showRecipesView) {
            RecipesView(onAdd: { newItem in
                linkItemSelection = newItem
            })
        }
        .alert("Conflict: Both Locations Exist", isPresented: $showConflictAlert) {
            Button("Keep From (Original)", role: .destructive) {
                if let item = conflictLinkItem {
                    resolveConflict(linkItem: item, keepFrom: true)
                }
            }
            Button("Keep To (Backup)", role: .destructive) {
                if let item = conflictLinkItem {
                    resolveConflict(linkItem: item, keepFrom: false)
                }
            }
            Button("Cancel", role: .cancel) {
                conflictLinkItem = nil
            }
        } message: {
            Text("Both the original location and backup location have existing files. Which one would you like to keep? The other will be moved to iCloud with a 'backup' suffix and date.")
        }
    }

    private func pullFromRepository() {
        Task {
            let result = Linker.shell("git pull")
            print("Git pull result: \(result)")

            // Reload settings after pull
            do {
                let settings = try await SettingsManager.shared.loadSettings()
                await syncSettingsToDatabase(settings: settings)
            } catch {
                print("Error reloading settings after pull: \(error)")
            }
        }
    }

    @MainActor
    private func syncSettingsToDatabase(settings: SettingsYaml) async {
        // Fetch existing items
        let descriptor = FetchDescriptor<LinkItem>()
        let existingItems = (try? modelContext.fetch(descriptor)) ?? []

        // Create a set of existing names for quick lookup
        let existingNames = Set(existingItems.map { $0.name })

        // Add new items from YAML that don't exist in database
        for linkConfig in settings.links {
            if !existingNames.contains(linkConfig.name) {
                let newItem = LinkItem(
                    name: linkConfig.name,
                    from: linkConfig.from,
                    to: linkConfig.to
                )
                modelContext.insert(newItem)
            }
        }

        try? modelContext.save()
    }

    private func expandTilde(_ path: String) -> String {
        return PathUtility.expandTildeToRealHome(path)
    }

    private func onRun(linkItem: LinkItem) -> Void {
        // Generate the full destination path (backup location in iCloud)
        let toPath = "\(Config.expandedBackupPath)/\(linkItem.to)"

        // Expand the from path (original app location)
        let fromPath = PathUtility.expandTildeToRealHome(linkItem.from)

        // Use shell commands to check existence (bypasses sandbox restrictions)
        let escapedFromPath = fromPath.replacingOccurrences(of: "'", with: "'\\''")
        let escapedToPath = toPath.replacingOccurrences(of: "'", with: "'\\''")

        let fromExistsResult = Linker.shell("test -e '\(escapedFromPath)' && echo 'yes' || echo 'no'").trimmingCharacters(in: .whitespacesAndNewlines)
        let toExistsResult = Linker.shell("test -e '\(escapedToPath)' && echo 'yes' || echo 'no'").trimmingCharacters(in: .whitespacesAndNewlines)

        let fromExists = (fromExistsResult == "yes")
        let toExists = (toExistsResult == "yes")

        var isFromSymlink = false
        var isToSymlink = false

        if fromExists {
            let symlinkCheck = Linker.shell("test -L '\(escapedFromPath)' && echo 'yes' || echo 'no'").trimmingCharacters(in: .whitespacesAndNewlines)
            isFromSymlink = (symlinkCheck == "yes")
        }

        if toExists {
            let symlinkCheck = Linker.shell("test -L '\(escapedToPath)' && echo 'yes' || echo 'no'").trimmingCharacters(in: .whitespacesAndNewlines)
            isToSymlink = (symlinkCheck == "yes")
        }

        // Case 1: Both exist and neither is a symlink - conflict!
        if fromExists && !isFromSymlink && toExists && !isToSymlink {
            conflictLinkItem = linkItem
            conflictFromPath = fromPath
            conflictToPath = toPath
            showConflictAlert = true
            return
        }

        // Case 2: From exists and is not a symlink - move it to backup location
        if fromExists && !isFromSymlink {
            print("Moving '\(fromPath)' to '\(toPath)'")

            // Create parent directory if needed using osascript (has proper permissions)
            let parentDir = (toPath as NSString).deletingLastPathComponent
            let escapedParentDir = parentDir.replacingOccurrences(of: "\"", with: "\\\"")
            let createDirScript = "do shell script \"mkdir -p \\\"\(escapedParentDir)\\\"\""
            print("DEBUG: Creating directory with osascript")
            let osascriptResult = Linker.shell("osascript -e '\(createDirScript)'")
            if !osascriptResult.isEmpty {
                print("DEBUG: osascript result: \(osascriptResult)")
            }

            // Copy the file/folder using ditto (macOS native tool that handles permissions better)
            let escapedFromForOsascript = fromPath.replacingOccurrences(of: "\"", with: "\\\"")
            let escapedToForOsascript = toPath.replacingOccurrences(of: "\"", with: "\\\"")
            let copyScript = "do shell script \"ditto \\\"\(escapedFromForOsascript)\\\" \\\"\(escapedToForOsascript)\\\"\""
            print("DEBUG: Copying with osascript and ditto")
            let cpResult = Linker.shell("osascript -e '\(copyScript)'")
            if !cpResult.isEmpty {
                print("Error copying file: \(cpResult)")
                return
            }
            print("DEBUG: Copy successful")

            // Remove the original using osascript
            let removeScript = "do shell script \"rm -rf \\\"\(escapedFromForOsascript)\\\"\""
            print("DEBUG: Removing original with osascript")
            let rmResult = Linker.shell("osascript -e '\(removeScript)'")
            if !rmResult.isEmpty {
                print("Error removing original: \(rmResult)")
                return
            }
            print("DEBUG: Remove successful")
        }

        // Case 3: Create symlink from original location to backup location
        print("Creating symlink at '\(fromPath)' -> '\(toPath)'")
        Linker.linkOrMove(from: toPath, to: fromPath)

        // Run defaults command if present
        if !linkItem.defaults.isEmpty {
            let result = Linker.shell(linkItem.defaults)
            print("Defaults command result: \(result)")
        }
    }

    private func resolveConflict(linkItem: LinkItem, keepFrom: Bool) {
        let toPath = "\(Config.expandedBackupPath)/\(linkItem.to)"
        let fromPath = PathUtility.expandTildeToRealHome(linkItem.from)

        // Generate backup name with date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let backupName = "\(linkItem.to)-backup-\(dateString)"
        let backupPath = "\(Config.expandedBackupPath)/\(backupName)"

        // Escape paths for osascript
        let escapedToPath = toPath.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedFromPath = fromPath.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBackupPath = backupPath.replacingOccurrences(of: "\"", with: "\\\"")

        if keepFrom {
            // Keep from (original), move to (backup) to backup location
            print("Moving backup '\(toPath)' to '\(backupPath)'")
            let copyScript1 = "do shell script \"ditto \\\"\(escapedToPath)\\\" \\\"\(escapedBackupPath)\\\"\""
            let cpResult1 = Linker.shell("osascript -e '\(copyScript1)'")
            if !cpResult1.isEmpty {
                print("Error copying backup: \(cpResult1)")
                return
            }
            let removeScript1 = "do shell script \"rm -rf \\\"\(escapedToPath)\\\"\""
            let rmResult1 = Linker.shell("osascript -e '\(removeScript1)'")
            if !rmResult1.isEmpty {
                print("Error removing backup: \(rmResult1)")
                return
            }

            // Move from to to location
            print("Moving '\(fromPath)' to '\(toPath)'")
            let copyScript2 = "do shell script \"ditto \\\"\(escapedFromPath)\\\" \\\"\(escapedToPath)\\\"\""
            let cpResult2 = Linker.shell("osascript -e '\(copyScript2)'")
            if !cpResult2.isEmpty {
                print("Error copying from: \(cpResult2)")
                return
            }
            let removeScript2 = "do shell script \"rm -rf \\\"\(escapedFromPath)\\\"\""
            let rmResult2 = Linker.shell("osascript -e '\(removeScript2)'")
            if !rmResult2.isEmpty {
                print("Error removing from: \(rmResult2)")
                return
            }
        } else {
            // Keep to (backup), move from (original) to backup location
            print("Moving original '\(fromPath)' to '\(backupPath)'")
            let copyScript = "do shell script \"ditto \\\"\(escapedFromPath)\\\" \\\"\(escapedBackupPath)\\\"\""
            let cpResult = Linker.shell("osascript -e '\(copyScript)'")
            if !cpResult.isEmpty {
                print("Error copying original: \(cpResult)")
                return
            }
            let removeScript = "do shell script \"rm -rf \\\"\(escapedFromPath)\\\"\""
            let rmResult = Linker.shell("osascript -e '\(removeScript)'")
            if !rmResult.isEmpty {
                print("Error removing original: \(rmResult)")
                return
            }
        }

        // Create symlink
        print("Creating symlink at '\(fromPath)' -> '\(toPath)'")
        Linker.linkOrMove(from: toPath, to: fromPath)

        // Run defaults command if present
        if !linkItem.defaults.isEmpty {
            let result = Linker.shell(linkItem.defaults)
            print("Defaults command result: \(result)")
        }

        // Clear conflict state
        conflictLinkItem = nil
        conflictFromPath = ""
        conflictToPath = ""
    }

    private func onUninstall(linkItem: LinkItem) -> Void {
        // Delete the symlink at the "from" path
        let fromPath = PathUtility.expandTildeToRealHome(linkItem.from)
        let result = Linker.shell("rm '\(fromPath)'")
        print("Uninstall result: \(result)")
    }

    private func onSave(linkItem: LinkItem) -> Void {
        // Check for duplicate names
        let duplicates = linkItems.filter { $0.name == linkItem.name && $0 != linkItem }
        if !duplicates.isEmpty {
            // Make name unique by appending a number
            var counter = 1
            var uniqueName = "\(linkItem.name) (\(counter))"
            while linkItems.contains(where: { $0.name == uniqueName && $0 != linkItem }) {
                counter += 1
                uniqueName = "\(linkItem.name) (\(counter))"
            }
            linkItem.name = uniqueName
        }

        // With @Bindable, changes are automatically tracked
        // Save to database
        try? modelContext.save()

        // Also save to YAML file
        Task {
            await saveToYAML()
        }
    }

    @MainActor
    private func saveToYAML() async {
        // Convert all LinkItems to YAML format
        let linkConfigs = linkItems.map { item in
            SettingsYaml.LinkConfig(
                name: item.name,
                from: item.from,
                to: item.to,
                defaults: item.defaults.isEmpty ? nil : item.defaults
            )
        }

        let settings = SettingsYaml(links: linkConfigs)

        do {
            try await SettingsManager.shared.saveSettings(settings)
            print("Settings saved to YAML")
        } catch {
            print("Error saving settings to YAML: \(error)")
        }
    }

    private func onDelete(linkItem: LinkItem) -> Void {
        // First uninstall the symlink
        onUninstall(linkItem: linkItem)

        // Find the index of the item to delete
        guard let index = linkItems.firstIndex(of: linkItem) else { return }

        // Determine next selection
        let nextSelection: LinkItem? = {
            if index < linkItems.count - 1 {
                // Select next item if available
                return linkItems[index + 1]
            } else if index > 0 {
                // Select previous item if we're deleting the last item
                return linkItems[index - 1]
            } else {
                // No items left
                return nil
            }
        }()

        // Then delete from database
        withAnimation {
            modelContext.delete(linkItem)
            linkItemSelection = nextSelection
        }
        // Save to YAML after deletion
        Task {
            await saveToYAML()
        }
    }

    private func addItem() {
        withAnimation {
            // Generate a unique name
            var baseName = Date().formatted()
            var uniqueName = baseName
            var counter = 1

            // Check if name already exists
            while linkItems.contains(where: { $0.name == uniqueName }) {
                uniqueName = "\(baseName) (\(counter))"
                counter += 1
            }

            let newItem = LinkItem(name: uniqueName)
            modelContext.insert(newItem)
            linkItemSelection = newItem
        }
        // Save to YAML after adding
        Task {
            await saveToYAML()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(linkItems[index])
            }
        }
    }
}



#Preview("LinkItemList filled") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: LinkItem.self, configurations: config)

    let sampleItems = [
        LinkItem(name: "Dropbox", from: "/Users/user/Dropbox", to: "/opt/dropbox"),
        LinkItem(name: "Adobe Fonts", from: "/Library/Application Support/Adobe/CoreSync/plugins/livetype", to: "/System/Library/Fonts"),
        LinkItem(name: "Audio Plugins", from: "/Library/Audio/Plug-Ins", to: "/usr/local/audio")
    ]

    for item in sampleItems {
        container.mainContext.insert(item)
    }

    return LinkItemListView()
        .modelContainer(container)
}

/*
#Preview("LinkItemList empty") {
    struct Preview: View {
        var linkItems: [LinkItem] = []
        var body: some View {
            LinkItemListView(linkItems: linkItems)
        }
    }

    return Preview()
}

*/
