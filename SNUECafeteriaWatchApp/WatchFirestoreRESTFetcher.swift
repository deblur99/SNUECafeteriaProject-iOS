//
//  WatchFirestoreRESTFetcher.swift
//  SNUECafeteriaWatchApp
//

import Foundation

/// watchOS는 Firebase SDK Firestore를 지원하지 않아 REST API로 `meals`를 가져온다.
/// 독립 모드에서는 워치에 필요한 이번 주(월~일, KST) 문서만 `runQuery`로 요청한다.
nonisolated enum WatchFirestoreRESTFetcher {
    enum FetchError: Error {
        case missingConfiguration
        case invalidResponse
        case requestFailed(Int)
    }

    static func fetchCachedMeals(for referenceDate: Date = .now) async throws -> [CachedDayMeal] {
        guard let config = loadConfiguration() else { throw FetchError.missingConfiguration }
        guard let weekInterval = Calendar.kstWeekInterval(for: referenceDate) else {
            throw FetchError.invalidResponse
        }

        var components = URLComponents(
            string: "https://firestore.googleapis.com/v1/projects/\(config.projectID)/databases/(default)/documents:runQuery"
        )!
        components.queryItems = [URLQueryItem(name: "key", value: config.apiKey)]
        guard let url = components.url else { throw FetchError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            RunQueryRequest.weekRange(from: weekInterval.start, until: weekInterval.end)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw FetchError.invalidResponse }
        guard (200 ... 299).contains(http.statusCode) else { throw FetchError.requestFailed(http.statusCode) }

        let rows = try JSONDecoder().decode([FirestoreRunQueryRow].self, from: data)
        let meals = rows.compactMap { row -> CachedDayMeal? in
            guard let document = row.document else { return nil }
            return parseMeal(document: document)
        }
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

// MARK: - Request

private nonisolated struct RunQueryRequest: Encodable {
    let structuredQuery: StructuredQuery

    static func weekRange(from start: Date, until endExclusive: Date) -> RunQueryRequest {
        RunQueryRequest(
            structuredQuery: StructuredQuery(
                from: [CollectionSelector(collectionId: "meals")],
                where: CompositeWhere(
                    compositeFilter: CompositeFilter(
                        op: "AND",
                        filters: [
                            .field(
                                path: "date",
                                op: "GREATER_THAN_OR_EQUAL",
                                timestamp: WatchFirestoreRESTFetcherTimestamp.string(start)
                            ),
                            .field(
                                path: "date",
                                op: "LESS_THAN",
                                timestamp: WatchFirestoreRESTFetcherTimestamp.string(endExclusive)
                            ),
                        ]
                    )
                ),
                orderBy: [
                    OrderBy(
                        field: FieldReference(fieldPath: "date"),
                        direction: "ASCENDING"
                    ),
                ]
            )
        )
    }
}

/// `ISO8601DateFormatter`를 요청 인코딩 경로에서 재사용하기 위한 헬퍼.
private nonisolated enum WatchFirestoreRESTFetcherTimestamp {
    static func string(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}

private nonisolated struct StructuredQuery: Encodable {
    let from: [CollectionSelector]
    let `where`: CompositeWhere
    let orderBy: [OrderBy]
}

private nonisolated struct CollectionSelector: Encodable {
    let collectionId: String
}

private nonisolated struct CompositeWhere: Encodable {
    let compositeFilter: CompositeFilter
}

private nonisolated struct CompositeFilter: Encodable {
    let op: String
    let filters: [QueryFilter]
}

private nonisolated enum QueryFilter: Encodable {
    case field(path: String, op: String, timestamp: String)

    private enum CodingKeys: String, CodingKey {
        case fieldFilter
    }

    private struct FieldFilterBody: Encodable {
        let field: FieldReference
        let op: String
        let value: TimestampValue
    }

    private struct TimestampValue: Encodable {
        let timestampValue: String
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .field(path, op, timestamp):
            try container.encode(
                FieldFilterBody(
                    field: FieldReference(fieldPath: path),
                    op: op,
                    value: TimestampValue(timestampValue: timestamp)
                ),
                forKey: .fieldFilter
            )
        }
    }
}

private nonisolated struct FieldReference: Encodable {
    let fieldPath: String
}

private nonisolated struct OrderBy: Encodable {
    let field: FieldReference
    let direction: String
}

// MARK: - Response

private nonisolated struct FirestoreRunQueryRow: Decodable {
    let document: FirestoreRESTDocument?
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
