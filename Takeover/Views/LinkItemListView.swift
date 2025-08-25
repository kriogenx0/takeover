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
                List {
                    ForEach(linkItems, id: \.self) { linkItem in
                        NavigationLink {
                            Text("Item at \(linkItem.name)")
                        } label: {
                            Text(linkItem.name)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(SidebarListStyle())
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            } else {
                Text("No Link Items")
            }
        } detail: {
            if linkItemSelection != nil {
//                print("Link Item Selection: \(linkItemSelection!.name)")
                LinkItemDetailView(linkItem: linkItemSelection!)
            }
        }/*.toolbar(content: {
            ToolbarItem(content: {
                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            })
        })*/
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
    /*
    struct Preview: View {
        var linkItems: [LinkItem] = [
            LinkItem(name: "Apple Music"),
            LinkItem(name: "Another one"),
            LinkItem(name: "A third one")
        ]
        var body: some View {
            LinkItemListView(linkItems: linkItems)
        }
    }

    return Preview()
    */

    LinkItemListView()
            .modelContainer(for: LinkItem.self, inMemory: true)
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
