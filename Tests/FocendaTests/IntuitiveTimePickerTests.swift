import XCTest
import SwiftUI
@testable import FocendaCore

final class IntuitiveTimePickerTests: XCTestCase {

    func testFormattedTimeString() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 27
        components.hour = 17
        components.minute = 30
        let date = calendar.date(from: components)!

        let binding = Binding.constant(date)
        let picker = IntuitiveTimePicker("Test", selection: binding)

        XCTAssertEqual(picker.currentHour, 17)
        XCTAssertEqual(picker.currentMinute, 30)
        XCTAssertEqual(picker.formattedTimeString, "17:30")
    }

    func testSetTimeMutatesHourAndMinutePreservingDate() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 10
        components.hour = 9
        components.minute = 15
        var date = calendar.date(from: components)!

        let binding = Binding(get: { date }, set: { date = $0 })
        let picker = IntuitiveTimePicker(selection: binding)

        picker.setTime(hour: 14, minute: 45)

        let resultComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        XCTAssertEqual(resultComponents.year, 2026)
        XCTAssertEqual(resultComponents.month, 5)
        XCTAssertEqual(resultComponents.day, 10)
        XCTAssertEqual(resultComponents.hour, 14)
        XCTAssertEqual(resultComponents.minute, 45)
    }

    func testAdjustHourWrapsAroundCorrectly() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = 23
        components.minute = 0
        var date = calendar.date(from: components)!

        let binding = Binding(get: { date }, set: { date = $0 })
        let picker = IntuitiveTimePicker(selection: binding)

        // Increment past 23 -> 0
        picker.adjustHour(by: 1)
        XCTAssertEqual(picker.currentHour, 0)

        // Decrement below 0 -> 23
        picker.adjustHour(by: -1)
        XCTAssertEqual(picker.currentHour, 23)
    }

    func testAdjustMinuteCalculatesCorrectly() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = 10
        components.minute = 55
        var date = calendar.date(from: components)!

        let binding = Binding(get: { date }, set: { date = $0 })
        let picker = IntuitiveTimePicker(selection: binding)

        // Add 10 minutes -> 11:05
        picker.adjustMinute(by: 10)
        XCTAssertEqual(picker.currentHour, 11)
        XCTAssertEqual(picker.currentMinute, 5)

        // Subtract 15 minutes -> 10:50
        picker.adjustMinute(by: -15)
        XCTAssertEqual(picker.currentHour, 10)
        XCTAssertEqual(picker.currentMinute, 50)
    }

    func testApplyPresetSetsSpecificTime() {
        var date = Date()
        let binding = Binding(get: { date }, set: { date = $0 })
        let picker = IntuitiveTimePicker(selection: binding)

        picker.applyPreset(hour: 9, minute: 0)
        XCTAssertEqual(picker.currentHour, 9)
        XCTAssertEqual(picker.currentMinute, 0)

        picker.applyPreset(hour: 12, minute: 0)
        XCTAssertEqual(picker.currentHour, 12)
        XCTAssertEqual(picker.currentMinute, 0)

        picker.applyPreset(hour: 14, minute: 0)
        XCTAssertEqual(picker.currentHour, 14)
        XCTAssertEqual(picker.currentMinute, 0)

        picker.applyPreset(hour: 17, minute: 0)
        XCTAssertEqual(picker.currentHour, 17)
        XCTAssertEqual(picker.currentMinute, 0)

        picker.applyPreset(hour: 19, minute: 0)
        XCTAssertEqual(picker.currentHour, 19)
        XCTAssertEqual(picker.currentMinute, 0)

        picker.applyPreset(hour: 21, minute: 0)
        XCTAssertEqual(picker.currentHour, 21)
        XCTAssertEqual(picker.currentMinute, 0)
    }

    func testApplyRoundedNow() {
        var date = Date()
        let binding = Binding(get: { date }, set: { date = $0 })
        let picker = IntuitiveTimePicker(selection: binding)

        picker.applyRoundedNow()
        XCTAssertTrue(picker.currentMinute % 5 == 0)
        XCTAssertTrue((0...23).contains(picker.currentHour))
    }

    func testApplyRelativeOffset() {
        var date = Date()
        let binding = Binding(get: { date }, set: { date = $0 })
        let picker = IntuitiveTimePicker(selection: binding)

        picker.applyRelativeOffset(minutes: 15)
        XCTAssertTrue((0...23).contains(picker.currentHour))
        XCTAssertTrue((0...59).contains(picker.currentMinute))
    }

    func testViewHierarchyRendersAcrossStyles() {
        let date = Date()
        let binding = Binding.constant(date)

        let standardPicker = IntuitiveTimePicker("Time", selection: binding, style: .standard)
        let compactPicker = IntuitiveTimePicker(selection: binding, style: .compact)
        let minimalPicker = IntuitiveTimePicker(selection: binding, style: .minimal)

        let standardHost = NSHostingView(rootView: standardPicker)
        let compactHost = NSHostingView(rootView: compactPicker)
        let minimalHost = NSHostingView(rootView: minimalPicker)

        standardHost.frame = CGRect(x: 0, y: 0, width: 150, height: 40)
        compactHost.frame = CGRect(x: 0, y: 0, width: 100, height: 30)
        minimalHost.frame = CGRect(x: 0, y: 0, width: 80, height: 25)

        XCTAssertGreaterThan(standardHost.fittingSize.width, 0)
        XCTAssertGreaterThan(compactHost.fittingSize.width, 0)
        XCTAssertGreaterThan(minimalHost.fittingSize.width, 0)
    }
}
