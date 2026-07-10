//
//  Item.swift
//  gymapp
//
//  Created by Daniel Temalatzi Mojica on 10/07/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
