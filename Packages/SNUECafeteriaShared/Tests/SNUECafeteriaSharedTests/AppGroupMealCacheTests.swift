import Foundation
import Testing
@testable import SNUECafeteriaShared

struct AppGroupMealCacheTests {
    @Test
    func mealTypeLabels() {
        #expect(MealType.lunch.label == "중식")
        #expect(MealType.dinner.label == "석식")
    }

    @Test
    func notificationPayloadRoundTrip() {
        let date = DateFormatter.kstDash.date(from: "2026-07-27")!
        let info = NotificationPayload.mealInfo(date: date, mealType: .lunch)
        #expect(NotificationPayload.destination(from: info) == .meal)
        #expect(NotificationPayload.mealType(from: info) == .lunch)
        #expect(NotificationPayload.mealDate(from: info) == date)
    }
}
