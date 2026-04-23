import SwiftUI
import SwiftData

struct MacDefaultListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MacDefault.name) private var macDefaults: [MacDefault]
    @State private var selection: MacDefault? = nil

    var body: some View {
        NavigationSplitView {
            if macDefaults.isEmpty {
                Text("No Mac Defaults")
                    .foregroundColor(.secondary)
            } else {
                List(selection: $selection) {
                    ForEach(macDefaults, id: \.self) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                            if !item.value.isEmpty {
                                Text(item.value)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(item)
                        .contextMenu {
                            Button("Capture") {
                                MacDefaultInstaller.capture(macDefault: item)
                                try? modelContext.save()
                                Task { await saveToYAML() }
                            }
                            Button("Apply") {
                                MacDefaultInstaller.apply(macDefault: item)
                            }
                            .disabled(item.value.isEmpty)
                            Divider()
                            Button("Delete", role: .destructive) { onDelete(item) }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(SidebarListStyle())
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
                .onAppear {
                    if selection == nil && !macDefaults.isEmpty {
                        selection = macDefaults.first
                    }
                }
            }
        } detail: {
            if let item = selection {
                MacDefaultDetailView(macDefault: item, onSave: onSave, onDelete: onDelete)
            } else {
                Text("No Default Selected")
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: captureAll) {
                    Label("Capture All", systemImage: "square.and.arrow.down")
                }
                .help("Read current values from system for all defaults")
            }
            ToolbarItem(placement: .automatic) {
                Button(action: addItem) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }

    private func captureAll() {
        MacDefaultInstaller.captureAll(Array(macDefaults))
        try? modelContext.save()
        Task { await saveToYAML() }
    }

    private func addItem() {
        let newItem = MacDefault(name: "New Default")
        modelContext.insert(newItem)
        selection = newItem
        Task { await saveToYAML() }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(macDefaults[index]) }
        }
        Task { await saveToYAML() }
    }

    private func onSave(_ item: MacDefault) {
        try? modelContext.save()
        Task { await saveToYAML() }
    }

    private func onDelete(_ item: MacDefault) {
        let index = macDefaults.firstIndex(of: item)
        let nextSelection: MacDefault? = {
            guard let i = index else { return nil }
            if i < macDefaults.count - 1 { return macDefaults[i + 1] }
            if i > 0 { return macDefaults[i - 1] }
            return nil
        }()
        withAnimation {
            modelContext.delete(item)
            selection = nextSelection
        }
        Task { await saveToYAML() }
    }

    @MainActor
    private func saveToYAML() async {
        let configs = macDefaults
            .filter { !$0.value.isEmpty }
            .map { MacDefaultConfig(name: $0.name, value: $0.value) }
        guard var settings = SettingsManager.shared.settings else { return }
        settings.macDefaults = configs
        try? await SettingsManager.shared.saveSettings(settings)
    }
}

struct MacDefaultDetailView: View {
    @Bindable var macDefault: MacDefault

    var onSave: ((MacDefault) -> Void)?
    var onDelete: ((MacDefault) -> Void)?

    @State private var captureStatus: String? = nil
    @State private var captureIsSuccess = false
    @State private var saveTask: Task<Void, Never>?

    let typeOptions = ["string", "int", "integer", "float", "bool"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Name", text: $macDefault.name)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                Text("Default Configuration")
                    .font(.headline)

                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Domain")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("-g, com.apple.dock, NSGlobalDomain", text: $macDefault.domain)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("", selection: $macDefault.type) {
                            ForEach(typeOptions, id: \.self) { Text($0) }
                        }
                        .frame(minWidth: 90)
                    }
                }

                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("com.apple.trackpad.scaling", text: $macDefault.key)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Host Flag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("-currentHost", text: $macDefault.hostFlag)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .frame(minWidth: 110)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Value")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let status = captureStatus {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(captureIsSuccess ? .green : .orange)
                        }
                    }
                    TextField("captured value", text: $macDefault.value)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            }

            if !macDefault.domain.isEmpty && !macDefault.key.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Commands")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(macDefault.readCommand)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(4)
                    if !macDefault.value.isEmpty {
                        Text(macDefault.writeCommand)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(4)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Post Command (Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("killall Dock", text: $macDefault.postCommand)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            Spacer()

            Divider()

            HStack(spacing: 12) {
                Button("Delete", role: .destructive) {
                    onDelete?(macDefault)
                }

                Spacer()

                Button("Capture") {
                    let result = MacDefaultInstaller.capture(macDefault: macDefault)
                    let notFound = result.isEmpty
                        || result.contains("does not exist")
                        || result.contains("The domain/defaults pair")
                    captureStatus = notFound ? "Not found" : "Captured"
                    captureIsSuccess = !notFound
                    onSave?(macDefault)
                }
                .disabled(macDefault.domain.isEmpty || macDefault.key.isEmpty)

                Button("Apply") {
                    MacDefaultInstaller.apply(macDefault: macDefault)
                }
                .buttonStyle(.borderedProminent)
                .disabled(macDefault.value.isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 400)
        .onChange(of: macDefault.name)        { _, _ in scheduleSave() }
        .onChange(of: macDefault.domain)      { _, _ in scheduleSave() }
        .onChange(of: macDefault.key)         { _, _ in scheduleSave() }
        .onChange(of: macDefault.type)        { _, _ in scheduleSave() }
        .onChange(of: macDefault.value)       { _, _ in scheduleSave() }
        .onChange(of: macDefault.hostFlag)    { _, _ in scheduleSave() }
        .onChange(of: macDefault.postCommand) { _, _ in scheduleSave() }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if !Task.isCancelled { onSave?(macDefault) }
        }
    }
}
