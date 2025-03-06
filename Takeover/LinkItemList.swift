//
//  LinkItemList.swift
//  Takeover
//
//  Created by Alex Vaos on 3/4/25.
//

import Foundation
import SwiftUI

struct LinkItemList: View {
//    @Binding var linkItems: [LinkItem]
    @State private var itemSelection: LinkItem?
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(linkItems) { linkItem in
                    NavigationLink {
                        Text("Item at \(linkItem.name)")
                    } label: {
                        Text(linkItem.name)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
            }
        } detail: {
            if itemSelection != nil {
                LinkDetailView(linkItem: itemSelection)
            }
        }
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
                modelContext.delete(items[index])
            }
        }
    }
}


#Preview("LinkItemList empty") {
    let linkItems = [
        LinkItem(name: "Apple Music"),
        LinkItem(name: "Another one"),
        LinkItem(name: "A third one")
    ]
    
    LinkItemList(linkItems: linkItems)
}
