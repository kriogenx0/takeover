//
//  Item.swift
//  Takeover
//
//  Created by Alex Vaos on 2/12/25.
//

import Foundation
import SwiftData

@Model
final class LinkItem {
    
    var name: String
    var from: String?
    var to: String?
    
    init(name: String, from: String? = nil, to: String? = nil) {
        self.name = name
        self.from = from
        self.to = to
    }
}
