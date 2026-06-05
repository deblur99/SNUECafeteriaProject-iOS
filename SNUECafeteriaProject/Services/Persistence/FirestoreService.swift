//
//  FirestoreManager.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

import Foundation
import FirebaseFirestore

nonisolated final class FirestoreService: Sendable {
    static let shared = FirestoreService()
    
    private nonisolated(unsafe) let _db = Firestore.firestore()
    
    private var db: Firestore {
        lock.lock()
        defer { lock.unlock() }
        return _db
    }
    
    private let lock = NSLock()
    
    private init() {}
    
    func fetchAllMeals() async throws -> [DayMeal] {
        let snapshot = try await db.collection("meals").getDocuments()
        var meals: [FirestoreMealDTO] = []
        for document in snapshot.documents {
            print("\(document.documentID) => \(document.data())")
            let meal = try document.data(as: FirestoreMealDTO.self)
            meals.append(meal)
        }
        
        // FirestoreMealDTO 배열을 SwiftData Model 타입의 배열로 변환
        var results: [DayMeal] = []
        for meal in meals {
            let converted = meal.toPersistenceModel()
            results.append(converted)
        }
        
        return results
    }
    // 앱에서는 Firestore로부터 데이터 가져오기만 함
}
