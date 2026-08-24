//
//  WatchFirestoreRESTFetcher.swift
//  SNUECafeteriaWatchApp
//

import Foundation

/// watchOS는 Firebase SDK Firestore를 지원하지 않아 REST API로 `meals` 컬렉션을 가져온다.
nonisolated enum WatchFirestoreRESTFetcher {
    enum FetchError: Error {
        case missingConfiguration
        case invalidResponse
        case requestFailed(Int)
    }

    static func fetchCachedMeals() async throws -> [CachedDayMeal] {
        guard let config = loadConfiguration() else { throw FetchError.missingConfiguration }

        var components = URLComponents(string: "https://firestore.googleapis.com/v1/projects/\(config.projectID)/databases/(default)/documents/meals")!
        components.queryItems = [URLQueryItem(name: "key", value: config.apiKey)]
        guard let url = components.url else { throw FetchError.invalidResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw FetchError.invalidResponse }
        guard (200 ... 299).contains(http.statusCode) else { throw FetchError.requestFailed(http.statusCode) }

        let decoded = try JSONDecoder().decode(FirestoreDocumentsResponse.self, from: data)
        let meals = (decoded.documents ?? []).compactMap(parseMeal(document:))
        return meals.sorted { $0.date < $1.date }
    }

    private static func loadConfiguration() -> (projectID: String, apiKey: String)? {
        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let projectID = plist["PROJECT_ID"] as? String,
              let apiKey = plist["API_KEY"] as? String
        else { return nil }
        return (projectID, apiKey)
    }

    private static func parseMeal(document: FirestoreRESTDocument) -> CachedDayMeal? {
        let fields = document.fields

        guard let date = fields["date"]?.timestampValue.flatMap(parseTimestamp),
              let createdAt = fields["createdAt"]?.timestampValue.flatMap(parseTimestamp)
        else { return nil }

        let lunchItems = menuItems(from: fields["lunch"]?.arrayValue?.values ?? [])
        let dinnerItems = menuItems(from: fields["dinner"]?.arrayValue?.values ?? [])
        let isHoliday = fields["isHoliday"]?.booleanValue ?? false

        return CachedDayMeal(
            date: Calendar.kst.startOfDay(for: date),
            lunchItems: lunchItems,
            dinnerItems: dinnerItems,
            isHoliday: isHoliday,
            createdAt: createdAt
        )
    }

    private static func menuItems(from values: [FirestoreFieldValue]) -> [CachedMenuItem] {
        values.enumerated().compactMap { index, value in
            guard let name = value.mapValue?.fields?["name"]?.stringValue else { return nil }
            return CachedMenuItem(name: name, sortIndex: index)
        }
    }

    private static func parseTimestamp(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

private nonisolated struct FirestoreDocumentsResponse: Decodable {
    let documents: [FirestoreRESTDocument]?
}

private nonisolated struct FirestoreRESTDocument: Decodable {
    let fields: [String: FirestoreFieldValue]
}

private nonisolated struct FirestoreFieldValue: Decodable {
    let stringValue: String?
    let booleanValue: Bool?
    let integerValue: String?
    let timestampValue: String?
    let arrayValue: FirestoreArrayValue?
    let mapValue: FirestoreMapValue?
}

private nonisolated struct FirestoreArrayValue: Decodable {
    let values: [FirestoreFieldValue]?
}

private nonisolated struct FirestoreMapValue: Decodable {
    let fields: [String: FirestoreFieldValue]?
}
