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
        TabView {
            LinkItemListView()
                .tabItem { Label("Links", systemImage: "link") }
            MacDefaultListView()
                .tabItem { Label("Mac Defaults", systemImage: "gearshape") }
            AppInstallerListView()
                .tabItem { Label("Applications", systemImage: "app.badge.checkmark") }
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: [LinkItem.self, MacDefault.self, AppInstaller.self], inMemory: true)
}
