//
//  ContentView.swift
//  Takeover
//
//  Created by Alex Vaos on 2/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        LinkItemListView()
    }
}


#Preview {
    ContentView()
        .modelContainer(for: LinkItem.self, inMemory: true)
}
