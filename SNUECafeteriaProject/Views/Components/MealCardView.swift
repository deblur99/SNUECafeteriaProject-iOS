//
//  MealCardView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI

struct MealCardView: View {
    let menus: [String] = [
        "홍국쌀밥",
        "된장찌개",
        "사태갈비찜",
        "두부양념조림",
        "삼색겨자냉채",
        "열무김치",
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("금")
                    .foregroundStyle(.white)
                    .bold()
                    .padding()
                    .background(Circle().fill(.blue))
                
                VStack(alignment: .leading) {
                    Text("4/24 (금)")
                    Text("중식")
                        .bold()
                }
                
                Spacer()
            }
            
            ForEach(menus, id: \.self) { menu in
                Text(menu)
                    .padding(.vertical, 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .shadow(radius: 4, x: 2, y: 4)
        )
    }
}

#Preview {
    MealCardView()
        .padding()
}
