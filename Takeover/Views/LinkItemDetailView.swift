//
//  ItemDetail.swift
//  Takeover
//
//  Created by Alex Vaos on 2/13/25.
//

import SwiftUI
import AppKit

struct LinkItemDetailView: View {
    @State private var form: LinkItem

    private var onSave: ((LinkItem) -> Void)?
    private var onRun: ((LinkItem) -> Void)?
    private var onDelete: ((LinkItem) -> Void)?

    init(linkItem: LinkItem,
         onSave: ((LinkItem) -> Void)? = nil,
         onRun: ((LinkItem) -> Void)? = nil,
         onDelete: ((LinkItem) -> Void)? = nil) {
        self.form = linkItem
        self.onSave = onSave
        self.onRun = onRun
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // App Name Section
            VStack(alignment: .leading, spacing: 8) {
                Text("App Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Name", text: $form.name)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()

            // Symlink Paths Section
            VStack(alignment: .leading, spacing: 20) {
                Text("Symlink Configuration")
                    .font(.headline)

                // FROM Path (Source)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("From:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("(Source path to be linked)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Text(form.from.isEmpty ? "No path selected" : form.from)
                            .textSelection(.enabled)
                            .foregroundColor(form.from.isEmpty ? .secondary : .primary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)

                        Button("Browse...") {
                            Task {
                                if let path = try await selectFile() {
                                    form.from = path
                                }
                            }
                        }
                    }
                }

                // Arrow indicator
                HStack {
                    Spacer()
                    Image(systemName: "arrow.down")
                        .foregroundColor(.secondary)
                    Spacer()
                }

                // TO Path (Destination)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("To:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("(Destination for the symlink)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Text(form.to.isEmpty ? "No path selected" : form.to)
                            .textSelection(.enabled)
                            .foregroundColor(form.to.isEmpty ? .secondary : .primary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)

                        Button("Browse...") {
                            Task {
                                if let path = try await selectFile() {
                                    form.to = path
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            Divider()

            // Action Buttons
            HStack(spacing: 12) {
                Button("Save") {
                    onSave?(form)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Create Symlink") {
                    onRun?(form)
                }
                .buttonStyle(.borderedProminent)
                .disabled(form.from.isEmpty || form.to.isEmpty)

                Spacer()

                Button("Delete", role: .destructive) {
                    onDelete?(form)
                }
            }
        }
        .padding(24)
        .frame(minWidth: 400)
    }

    func selectFile() async throws -> String? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.canChooseFiles = true
        panel.message = "Select the path for the symlink"

        var filename: String?
        if panel.runModal() == .OK {
            filename = panel.url?.path
        }
        return filename
    }
}

#Preview("With Data") {
    let linkItem: LinkItem = LinkItem(
        name: "Fonts",
        from: "/Users/alex/Library/Fonts",
        to: "/Users/alex/Documents/Takeover/Fonts"
    )
    LinkItemDetailView(linkItem: linkItem)
}

#Preview("Empty") {
    let linkItem: LinkItem = LinkItem.empty()
    LinkItemDetailView(linkItem: linkItem)
}

