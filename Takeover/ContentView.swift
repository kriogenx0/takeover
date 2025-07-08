//
//  ContentView.swift
//  Takeover
//
//  Created by Alex Vaos on 2/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var linkItems: [LinkItem]

    var body: some View {
        LinkItemListView(linkItems: linkItems)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: LinkItem.self, inMemory: true)
}
