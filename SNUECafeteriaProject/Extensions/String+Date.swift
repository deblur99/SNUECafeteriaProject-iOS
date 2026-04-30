//
//  String+Date.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/30/26.
//

import Foundation

extension String {
    static func shortDateLabel(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d (E)"
        return formatter.string(from: date)
    }
}
