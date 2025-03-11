//
//  LinkItemList.swift
//  Takeover
//
//  Created by Alex Vaos on 3/4/25.
//

import Foundation
import SwiftUI
import SwiftData

/*

struct LinkListView: View {
    @Query var linkItems: [LinkItem]
    @State var selection: LinkItem? = nil

    var body: some View {
        NavigationSplitView {
            List(linkItems, id: \.self) { record in
                Text(record.name)
            }
            .listStyle(SidebarListStyle())
        } detail: {
            LinkDetailView(selection: $selection)
        } .toolbar(content: {
            ToolbarItem(content: {
                Text("Test")
            })
        })
    }
}
*/

struct LinkItemList: View {
    @Binding var linkItems: [LinkItem]
//    @Query var linkItems: [LinkItem]
    @State private var selection: LinkItem? = nil
    
    var body: some View {
        NavigationSplitView {
            if $linkItems.count > 0 {
                List {
                    ForEach($linkItems) { linkItem in
                        NavigationLink {
                            Text("Item at \(linkItem.name)")
                        } label: {
                            Text(linkItem.name)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            } else {
                Text("No Link Items")
            }
        } detail: {
            if selection != nil {
                LinkDetailView(linkItem: $selection)
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
//            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
//                modelContext.delete(items[index])
            }
        }
    }
}


#Preview("LinkItemList filled") {
    struct Preview: View {
        @State var linkItems: [LinkItem] = [
            LinkItem(name: "Apple Music"),
            LinkItem(name: "Another one"),
            LinkItem(name: "A third one")
        ]
        var body: some View {
            LinkItemList(linkItems: $linkItems)
        }
    }

    return Preview()
}
