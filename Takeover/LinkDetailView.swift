//
//  ItemDetail.swift
//  Takeover
//
//  Created by Alex Vaos on 2/13/25.
//

import SwiftUI

struct LinkDetailView: View {
    
    @Binding var linkItem: LinkItem?
    
    @State var form: LinkItem = LinkItem.emptyLinkItem()
    
//    init(linkItem: LinkItem) {
//        if linkItem != nil {
//            self.formToPath = linkItem.toPath
//            self.formFromPath = linkItem.fromPath
//        }
        
//        _linkItem = linkItem
        // self.formToPath = linkItem.toPath
//    }
    
    var body: some View {
        VStack (spacing: 20) {
//            TextField($form.name ?? "")
            //                .padding(20)
            
//            TextField("To Path", text: $form.to)
//            TextField("From Path", text: $form.from)
        }
    }
}

#Preview {
    let linkItem: LinkItem = LinkItem(
        name: "Dropbox",
        from: "/some/madeup/path",
        to: "/some/other/path"
    )
//    var binding = Binding<LinkItem?>(get: { linkItem }, set: { _ in })
//    LinkDetailView(linkItem: linkItem)
}
