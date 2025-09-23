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

    init(linkItem: LinkItem, onSave: ((LinkItem) -> Void)? = nil) {
        print("Name: \(linkItem.name)")
        self.form = linkItem
        self.onSave = onSave
    }

    var body: some View {
        VStack (spacing: 20) {
            TextField("Name", text: $form.name)

            HStack {
                Text(form.from.isEmpty ? "No path selected" : form.from)
                    .textSelection(.enabled)
                    .foregroundColor(form.from.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Browse...") {
                    Task {
                        if let path = try await selectFile() {
                            form.from = path
                        }
                    }
                }
            }

            HStack {
                Text(form.to.isEmpty ? "No path selected" : form.to)
                    .textSelection(.enabled)
                    .foregroundColor(form.to.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Browse...") {
                    Task {
                        if let path = try await selectFile() {
                            form.to = path
                        }
                    }
                }
            }

            Button("Save") {
                onSave?(form)
            }

            Spacer()
        }.padding(20)
    }

    func selectFile() async throws -> String? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        var filename: String?
        if panel.runModal() == .OK {
            filename = panel.url?.path
        }
        return filename
    }
}

/*
#Preview("Sample Data") {
    struct Preview: View {
        @Previewable @State var linkItem: LinkItem = LinkItem.empty()

        var body: some View {
            return LinkItemDetailView(linkItem: linkItem)
        }
    }

    let linkItem: LinkItem = LinkItem(
        name: "Dropbox",
        from: "/some/madeup/path",
        to: "/some/other/path"
    )
    LinkItemDetailView(linkItem: linkItem)
}
 */

#Preview("Empty") {
    let linkItem: LinkItem = LinkItem.empty()
    LinkItemDetailView(linkItem: linkItem)
}

