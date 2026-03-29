//
//  main.swift
//  TakeoverCLI
//
//  Created by Alex Vaos on 1/20/26.
//

import Foundation

// CLI Entry Point
func main() {
    let arguments = CommandLine.arguments

    // Remove the first argument (program name)
    let cliArgs = Array(arguments.dropFirst())

    do {
        let repositories = try Repository.load()
        let settings = try UserSettings.load()

        switch cliArgs.count {
        case 0:
            // No arguments: List all repository names
            listRepositories(repositories)

        case 1:
            // One argument: Show detailed info about repository
            let repoName = cliArgs[0]
            showRepositoryInfo(repoName, repositories: repositories, settings: settings)

        case 2:
            // Two arguments: repository name and action (enable/disable)
            let repoName = cliArgs[0]
            let action = cliArgs[1].lowercased()

            if action == "enable" {
                try enableRepository(repoName, repositories: repositories, settings: settings, userSettings: userSettings)
            } else if action == "disable" {
                try disableRepository(repoName, repositories: repositories, settings: settings, userSettings: userSettings)
            } else {
                print("Error: Second argument must be 'enable' or 'disable'")
                printUsage()
                exit(1)
            }

        default:
            print("Error: Too many arguments")
            printUsage()
            exit(1)
        }

    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

// MARK: - CLI Functions

func printUsage() {
    print("""
    Usage: takeover [repository_name] [enable|disable]

    Commands:
      takeover                    - List all available repositories
      takeover <name>             - Show detailed information about a repository
      takeover <name> enable      - Enable/create link for the repository
      takeover <name> disable     - Disable/restore original state for the repository
    """)
}

func listRepositories(_ repositories: [RepositoryStructure]) {
    print("Available repositories:")
    for repo in repositories {
        print("  - \(repo.name)")
    }
}

func showRepositoryInfo(_ name: String, repositories: [RepositoryStructure], settings: Settings) {
    guard let repo = repositories.first(where: { $0.name.lowercased() == name.lowercased() }) else {
        print("Error: Repository '\(name)' not found")
        print("Available repositories:")
        listRepositories(repositories)
        exit(1)
    }

    print("Repository: \(repo.name)")
    print("  From: \(repo.from)")
    if let to = repo.to {
        print("  To: \(to)")
    }
    if let after = repo.after {
        print("  After commands: \(after.joined(separator: ", "))")
    }

    // Show current status
    let isEnabled = getSettingValue(for: repo.name, in: settings)
    print("  Status: \(isEnabled ? "enabled" : "disabled")")
}

func enableRepository(_ name: String, repositories: [RepositoryStructure], settings: inout Settings, userSettings: UserSettings) throws {
    guard let repo = repositories.first(where: { $0.name.lowercased() == name.lowercased() }) else {
        print("Error: Repository '\(name)' not found")
        exit(1)
    }

    print("Enabling repository: \(repo.name)")

    // Check if 'to' path is specified (required for linking)
    guard let toPath = repo.to else {
        print("Error: Repository '\(repo.name)' does not have a 'to' path specified, cannot create link")
        exit(1)
    }

    // Expand tilde in paths
    let expandedFrom = expandTilde(in: repo.from)
    let expandedTo = expandTilde(in: toPath)

    print("  Creating link from \(expandedFrom) to \(expandedTo)")

    // Create the symbolic link
    Linker.linkOrMove(from: expandedFrom, to: expandedTo)

    // Update settings
    settings = updateSetting(for: repo.name, in: settings, value: true)

    // Save updated settings
    try userSettings.save(settings)

    // Run after commands if any
    if let afterCommands = repo.after {
        for command in afterCommands {
            let expandedCommand = command.replacingOccurrences(of: "$to", with: expandedTo)
            print("  Running: \(expandedCommand)")
            let result = Linker.shell(expandedCommand)
            if !result.isEmpty {
                print("  Output: \(result)")
            }
        }
    }

    print("Repository '\(repo.name)' enabled successfully")
}

func disableRepository(_ name: String, repositories: [RepositoryStructure], settings: inout Settings, userSettings: UserSettings) throws {
    guard let repo = repositories.first(where: { $0.name.lowercased() == name.lowercased() }) else {
        print("Error: Repository '\(name)' not found")
        exit(1)
    }

    print("Disabling repository: \(repo.name)")

    // Check if 'to' path is specified
    guard let toPath = repo.to else {
        print("Error: Repository '\(repo.name)' does not have a 'to' path specified")
        exit(1)
    }

    // Expand tilde in paths
    let expandedFrom = expandTilde(in: repo.from)
    let expandedTo = expandTilde(in: toPath)

    print("  Removing link at \(expandedFrom)")

    // Remove the symbolic link if it exists
    if Linker.isLink(path: expandedFrom) {
        Linker.delete(path: expandedFrom)
        print("  Link removed")
    } else {
        print("  No link found at \(expandedFrom)")
    }

    // Update settings
    settings = updateSetting(for: repo.name, in: settings, value: false)

    // Save updated settings
    try userSettings.save(settings)

    print("Repository '\(repo.name)' disabled successfully")
}

// MARK: - Helper Functions

func mapRepositoryNameToSettingKey(_ name: String) -> String {
    // Convert repository names to setting keys
    // Examples: "SSH" -> "ssh", "Table Plus" -> "table_plus", "Hosts" -> "hosts"
    let lowercased = name.lowercased()
    return lowercased.replacingOccurrences(of: " ", with: "_")
}

func getSettingValue(for appName: String, in settings: Settings) -> Bool {
    return UserSettings.isEnabled(appName, in: settings)
}

func updateSetting(for appName: String, in settings: Settings, value: Bool) -> Settings {
    return UserSettings.updateApp(appName, enabled: value, in: settings)
}

func expandTilde(in path: String) -> String {
    if path.hasPrefix("~") {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return path.replacingOccurrences(of: "~", with: home)
    }
    return path
}

// MARK: - Run Main

main()
