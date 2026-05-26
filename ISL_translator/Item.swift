//
//  Item.swift
//  ISL_translator
//
//  Created by Aryan Singh on 26/05/26.
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
