import XCTest
import Foundation
@testable import FocendaCore

final class AppDateFormatterTests: XCTestCase {

    private var fixedDate: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 1
        components.hour = 14
        components.minute = 30
        components.second = 0
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)!
    }

    func testIsoDateFormatter() {
        let formatted = AppDateFormatter.isoDate.string(from: fixedDate)
        XCTAssertEqual(formatted, "2026-09-01")
    }

    func testMonthDayFormatter() {
        let formatted = AppDateFormatter.monthDay.string(from: fixedDate)
        XCTAssertEqual(formatted, "Sep 1")
    }

    func testMonthYearFormatter() {
        let formatted = AppDateFormatter.monthYear.string(from: fixedDate)
        XCTAssertEqual(formatted, "September 2026")
    }

    func testDayOfWeekFormatter() {
        let formatted = AppDateFormatter.dayOfWeek.string(from: fixedDate)
        XCTAssertEqual(formatted, "Tuesday")
    }

    func testFullDateFormatter() {
        let formatted = AppDateFormatter.fullDate.string(from: fixedDate)
        XCTAssertEqual(formatted, "September 1, 2026")
    }

    func testTime12Formatter() {
        let formatted = AppDateFormatter.time12.string(from: fixedDate)
        XCTAssertEqual(formatted, "2:30 PM")
    }

    func testTime24Formatter() {
        let formatted = AppDateFormatter.time24.string(from: fixedDate)
        XCTAssertEqual(formatted, "14:30")
    }

    func testWeekdayMonthDayFormatter() {
        let formatted = AppDateFormatter.weekdayMonthDay.string(from: fixedDate)
        XCTAssertEqual(formatted, "Tue, Sep 1")
    }

    func testTodayAndTomorrowTime12Formatters() {
        let todayFormatted = AppDateFormatter.todayTime12.string(from: fixedDate)
        XCTAssertEqual(todayFormatted, "Today, 2:30 PM")

        let tmrwFormatted = AppDateFormatter.tomorrowTime12.string(from: fixedDate)
        XCTAssertEqual(tmrwFormatted, "Tmrw, 2:30 PM")
    }

    func testMonthDayTimeFormatters() {
        let time12 = AppDateFormatter.monthDayTime12.string(from: fixedDate)
        XCTAssertEqual(time12, "Sep 1, 2:30 PM")

        let time24 = AppDateFormatter.monthDayTime24.string(from: fixedDate)
        XCTAssertEqual(time24, "Sep 1, 14:30")
    }

    func testShortStyles() {
        let shortTime = AppDateFormatter.shortTime.string(from: fixedDate)
        XCTAssertFalse(shortTime.isEmpty)

        let shortDateTime = AppDateFormatter.shortDateTime.string(from: fixedDate)
        XCTAssertFalse(shortDateTime.isEmpty)
    }

    func testDateFormatterExtensionNamespace() {
        XCTAssertEqual(DateFormatter.focenda.isoDate.string(from: fixedDate), "2026-09-01")
        XCTAssertEqual(DateFormatter.focenda.monthDay.string(from: fixedDate), "Sep 1")
    }

    func testConcurrentFormattingThreadSafety() {
        let expectation = expectation(description: "Concurrent date formatting")
        expectation.expectedFulfillmentCount = 50

        let dates = (0..<50).map { offset in
            fixedDate.addingTimeInterval(TimeInterval(offset * 3600))
        }

        for (index, date) in dates.enumerated() {
            DispatchQueue.global().async {
                _ = AppDateFormatter.isoDate.string(from: date)
                _ = AppDateFormatter.monthDay.string(from: date)
                _ = AppDateFormatter.time12.string(from: date)
                _ = AppDateFormatter.time24.string(from: date)
                _ = AppDateFormatter.shortDateTime.string(from: date)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
    }
}
