//
//  ContentView.swift
//  Takeover
//
//  Created by Alex Vaos on 2/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
//    @Environment(\.modelContext) private var modelContext
    @Query private var linkItems: [LinkItem]

    var body: some View {
//        LinkItemList(linkItems: linkItems)
        List {
//            ForEach(linkItems) { linkItem in
//                Text("\(linkItem.title)")
//            }
        }
        
    }

}

struct ChildView: View {
    var linkItems: [LinkItem] = []

    init(linkItems: [LinkItem]) {
        self.linkItems = linkItems
    }
    
    var body: some View {
        List {
//            ForEach(linkItems) { linkItem in
//                Text("\(linkItem.title)")
//            }
        }
    }
}

#Preview {
    ContentView()
}
