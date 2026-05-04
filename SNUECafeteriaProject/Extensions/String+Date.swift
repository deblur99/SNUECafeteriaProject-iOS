//
//  String+Date.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/30/26.
//

import Foundation

extension String {
    static func shortDateLabel(from date: Date) -> String {
        DateFormatter.shortDateLabel.string(from: date)
    }
}
