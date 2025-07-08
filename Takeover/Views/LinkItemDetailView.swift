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
    
    init(linkItem: LinkItem) {
        print("Name: \(linkItem.name)")
        self.form = linkItem
    }
    
    var body: some View {
        VStack (spacing: 20) {
            TextField("Name", text: $form.name)
            TextField("To Path", text: $form.to)
            TextField("From Path", text: $form.from)
        }.padding(20)
    }
}

#Preview("Sample Data") {
//    struct Preview: View {
//        @Previewable @State var linkItem: LinkItem = LinkItem.empty()
//        
//        var body: some View {
//            return LinkItemDetailView(linkItem: linkItem)
//        }
//    }
    
    let linkItem: LinkItem = LinkItem(
        name: "Dropbox",
        from: "/some/madeup/path",
        to: "/some/other/path"
    )
    LinkItemDetailView(linkItem: linkItem)
}

#Preview("Empty") {
    let linkItem: LinkItem = LinkItem.empty()
    LinkItemDetailView(linkItem: linkItem)
}
