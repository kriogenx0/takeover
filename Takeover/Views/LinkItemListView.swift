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

    @Query private var linkItems: [LinkItem] // Use @Query to fetch data
    //    var linkItems: [LinkItem] = []
//    @Binding var linkItems: [LinkItem]
    @State private var linkItemSelection: LinkItem? = nil

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
                LinkItemDetailView(linkItem: selectedItem)
            } else {
                Text("Select a Link Item")
                    .foregroundColor(.secondary)
            }
        }.toolbar(content: {
            ToolbarItem(content: {
                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            })
        })
    }
    
    private func addItem() {
        withAnimation {
            let newItem = LinkItem(name: Date().formatted())
            modelContext.insert(newItem)
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
        LinkItem(name: "Dropbox", from: "/Users/alex/Dropbox", to: "/opt/dropbox"),
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
