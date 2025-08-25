//
//  ItemDetail.swift
//  Takeover
//
//  Created by Alex Vaos on 2/13/25.
//

import SwiftUI

struct LinkItemDetailView: View {
//    @Binding var linkItem: LinkItem?
    @State private var form: LinkItem = LinkItem.empty()

    private var onSave: ((LinkItem) -> Void)? // Closure to handle saving

    init(linkItem: LinkItem) {
        print("Name: \(linkItem.name)")
        self.form = linkItem
    }

    var body: some View {
        VStack (spacing: 20) {
            TextField("Name", text: $form.name)

            HStack {
                TextField("To Path", text: $form.to)
                Button("")
            }
            TextField("From Path", text: $form.from)

            Button("Save") {
                onSave?(form) // Call the closure with the modified data
            }
        }.padding(20)
    }

    func selectFile() async throws -> String? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        var filename: String?
        if panel.runModal() == .OK {
            filename = panel.url?.lastPathComponent
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

