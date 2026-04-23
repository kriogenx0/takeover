import SwiftUI
import SwiftData

struct AppInstallerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppInstaller.name) private var installers: [AppInstaller]
    @State private var selection: AppInstaller? = nil

    var body: some View {
        NavigationSplitView {
            if installers.isEmpty {
                Text("No App Sources")
                    .foregroundColor(.secondary)
            } else {
                List(selection: $selection) {
                    ForEach(installers, id: \.self) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                            Text(item.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .tag(item)
                        .contextMenu {
                            Button("Delete", role: .destructive) { deleteInstaller(item) }
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets { deleteInstaller(installers[i]) }
                    }
                }
                .listStyle(SidebarListStyle())
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
                .onAppear {
                    if selection == nil { selection = installers.first }
                }
            }
        } detail: {
            if let item = selection {
                AppInstallerDetailView(installer: item, onSave: onSave, onDelete: deleteInstaller)
            } else {
                Text("No Source Selected")
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: addInstaller) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }

    private func addInstaller() {
        let item = AppInstaller(name: "New Source", path: "")
        modelContext.insert(item)
        selection = item
        Task { await saveToYAML() }
    }

    private func deleteInstaller(_ item: AppInstaller) {
        let index = installers.firstIndex(of: item)
        let next: AppInstaller? = {
            guard let i = index else { return nil }
            if i < installers.count - 1 { return installers[i + 1] }
            if i > 0 { return installers[i - 1] }
            return nil
        }()
        withAnimation {
            modelContext.delete(item)
            if selection == item { selection = next }
        }
        Task { await saveToYAML() }
    }

    private func onSave(_ item: AppInstaller) {
        try? modelContext.save()
        Task { await saveToYAML() }
    }

    @MainActor
    private func saveToYAML() async {
        let configs = installers.map { AppInstallerConfig(name: $0.name, path: $0.path) }
        guard var settings = SettingsManager.shared.settings else { return }
        settings.appInstallers = configs
        try? await SettingsManager.shared.saveSettings(settings)
    }
}

struct AppInstallerDetailView: View {
    @Bindable var installer: AppInstaller

    var onSave: ((AppInstaller) -> Void)?
    var onDelete: ((AppInstaller) -> Void)?

    @State private var discoveredApps: [DiscoveredApp] = []
    @State private var isScanning = false
    @State private var installStatus: [String: (success: Bool, message: String)] = [:]
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Source Name", text: $installer.name)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Folder Path")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("~/Downloads/Apps", text: $installer.path)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    Button("Browse") { browseForFolder() }
                        .padding(.top, 20)
                }
            }
            .padding(24)

            Divider()

            HStack {
                Text("Discovered Apps")
                    .font(.headline)
                Spacer()
                if isScanning {
                    ProgressView().scaleEffect(0.7)
                }
                Button("Scan") { scanApps() }
                    .disabled(installer.path.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            if discoveredApps.isEmpty && !isScanning {
                Text(installer.path.isEmpty ? "Set a folder path and tap Scan" : "No apps found — tap Scan to search")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(discoveredApps) { app in
                    AppRowView(app: app, status: installStatus[app.id]) {
                        installApp(app)
                    }
                    .contextMenu {
                        Button("Install") { installApp(app) }
                            .disabled(app.isInstalled)
                        Button("Reveal in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([app.fileURL])
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button("Delete", role: .destructive) { onDelete?(installer) }
                Spacer()
                Button("Install All") { installAll() }
                    .disabled(discoveredApps.filter { !$0.isInstalled }.isEmpty)
            }
            .padding(24)
        }
        .frame(minWidth: 420)
        .onChange(of: installer.name) { _, _ in scheduleSave() }
        .onChange(of: installer.path) { _, _ in scheduleSave() }
        .onAppear { if !installer.path.isEmpty { scanApps() } }
    }

    private func browseForFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            installer.path = url.path
            scheduleSave()
            scanApps()
        }
    }

    private func scanApps() {
        guard !installer.path.isEmpty else { return }
        isScanning = true
        Task {
            let apps = AppInstallerEngine.scan(at: installer.path)
            await MainActor.run {
                discoveredApps = apps
                isScanning = false
            }
        }
    }

    private func installApp(_ app: DiscoveredApp) {
        Task {
            let result = AppInstallerEngine.install(app)
            await MainActor.run {
                installStatus[app.id] = result
                // Re-scan to refresh isInstalled state
                discoveredApps = AppInstallerEngine.scan(at: installer.path)
            }
        }
    }

    private func installAll() {
        let pending = discoveredApps.filter { !$0.isInstalled }
        for app in pending { installApp(app) }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if !Task.isCancelled { onSave?(installer) }
        }
    }
}

struct AppRowView: View {
    let app: DiscoveredApp
    let status: (success: Bool, message: String)?
    let onInstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: app.fileType.systemImage)
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                Text(app.fileType.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let status = status {
                Text(status.message)
                    .font(.caption)
                    .foregroundColor(status.success ? .green : .red)
            } else if app.isInstalled {
                Label("Installed", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Button("Install", action: onInstall)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
    }
}
