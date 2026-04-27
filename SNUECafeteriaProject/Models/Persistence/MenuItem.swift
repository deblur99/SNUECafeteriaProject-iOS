//
//  MenuItem.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import Foundation
import SwiftData

@Model
final class MenuItem {
    var name: String
    
    init(name: String) {
        self.name = name
    }
}
