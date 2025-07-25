// Copyright © elvah. All rights reserved.

import Foundation
import Testing
@testable import ElvahCharge

@Suite("Time Model Tests")
struct TimeTests {

  // MARK: - Initialization Tests

  @Test("Initialize from time string - valid formats")
  func testInitFromTimeString() throws {
    let time1 = Time(timeString: "14:30", timeZone: TimeZone(identifier: "UTC")!)
    try #require(time1 != nil)
    #expect(time1!.hour == 14)
    #expect(time1!.minute == 30)
    #expect(time1!.second == nil)

    let time2 = Time(timeString: "09:15:45", timeZone: .current)
		try #require(time2 != nil)
    #expect(time2!.hour == 9)
    #expect(time2!.minute == 15)
    #expect(time2!.second == 45)

    let time3 = Time(timeString: "00:00")
		try #require(time3 != nil)
    #expect(time3!.hour == 0)
    #expect(time3!.minute == 0)
    #expect(time3!.second == nil)

    let time4 = Time(timeString: "23:59:59")
		try #require(time4 != nil)
    #expect(time4!.hour == 23)
    #expect(time4!.minute == 59)
    #expect(time4!.second == 59)
  }

  @Test("Initialize from time string - invalid formats")
  func testInitFromTimeStringInvalid() {
    #expect(Time(timeString: "invalid") == nil)
    #expect(Time(timeString: "25:00") == nil)
    #expect(Time(timeString: "14") == nil)
    #expect(Time(timeString: "") == nil)
    #expect(Time(timeString: "14:60") == nil)
    #expect(Time(timeString: "abc:def") == nil)
    #expect(Time(timeString: "14:-5") == nil)
    #expect(Time(timeString: "24:30") == nil)
  }

  @Test("Initialize from Date")
  func testInitFromDate() throws {
    let calendar = Calendar.current
    let components = DateComponents(
      year: 2024,
      month: 7,
      day: 24,
      hour: 15,
      minute: 45,
      second: 30
    )
    
    guard let date = calendar.date(from: components) else {
      return
    }

    let time = Time(date: date, timeZone: .current)
		try #require(time != nil)
    #expect(time!.hour == 15)
    #expect(time!.minute == 45)
    #expect(time!.second == 30)
  }

  // MARK: - String Formatting Tests

  @Test("Localized time string formatting")
  func testLocalizedTimeString() throws {
		let time1 = try #require(Time(hour: 14, minute: 30, timeZone: TimeZone(identifier: "UTC")!))
		let formatted1 = time1.localizedTimeString
    #expect(formatted1.contains("14"))
    #expect(formatted1.contains("30"))

    let time2 = try #require(Time(hour: 9, minute: 5, timeZone: .current))
		let formatted2 = time2.localizedTimeString
    #expect(formatted2.contains("09") || formatted2.contains("9"))
    #expect(formatted2.contains("05") || formatted2.contains("5"))

    // Test single-digit formatting
    let time3 = try #require(Time(hour: 7, minute: 3))
    let formatted3 = time3.localizedTimeString
    #expect(!formatted3.isEmpty)
  }

  // MARK: - Date Generation Tests

  @Test("Date for today generation")
  func testDateForToday() throws {
    let time = try #require(Time(hour: 14, minute: 30, second: 45, timeZone: .current))

    guard let date = time.dateForToday else {
      #expect(Bool(false), "dateForToday should not be nil for valid time")
      return
    }

    var calendar = Calendar.current
    calendar.timeZone = time.timeZone
    let components = calendar.dateComponents([.hour, .minute, .second], from: date)
    
    #expect(components.hour == 14)
    #expect(components.minute == 30)
    #expect(components.second == 45)
  }

  @Test("Date for today with different timezones")
  func testDateForTodayWithTimezones() throws {
    let utcTime = try #require(Time(hour: 12, minute: 0, timeZone: TimeZone(identifier: "UTC")!))
    let pstTime = try #require(Time(hour: 12, minute: 0, timeZone: TimeZone(identifier: "America/Los_Angeles")!))

    let utcDate = utcTime.dateForToday
    let pstDate = pstTime.dateForToday
    
    #expect(utcDate != nil)
    #expect(pstDate != nil)
    
    // The actual Date objects should be different due to timezone differences
    if let utcD = utcDate, let pstD = pstDate {
      #expect(utcD != pstD)
    }
  }

  // MARK: - Calculation Tests

  @Test("Seconds of day calculation")
  func testSecondsOfDay() throws {
    let midnight = try #require(Time(hour: 0, minute: 0, second: 0))
    #expect(midnight.secondsOfDay == 0)

    let oneHour = try #require(Time(hour: 1, minute: 0, second: 0))
    #expect(oneHour.secondsOfDay == 3600)

    let oneMinute = try #require(Time(hour: 0, minute: 1, second: 0))
    #expect(oneMinute.secondsOfDay == 60)

    let complex = try #require(Time(hour: 14, minute: 30, second: 45))
    #expect(complex.secondsOfDay == 14 * 3600 + 30 * 60 + 45)

    let noSeconds = try #require(Time(hour: 23, minute: 59, second: nil))
    #expect(noSeconds.secondsOfDay == 23 * 3600 + 59 * 60)
  }

  @Test("Difference in minutes calculation")
  func testDifferenceInMinutes() throws {
    let morning = try #require(Time(hour: 10, minute: 0))
    let laterMorning = try #require(Time(hour: 10, minute: 30))
    let afternoon = try #require(Time(hour: 11, minute: 15))

    #expect(morning.differenceInMinutes(to: laterMorning) == 30)
    #expect(morning.differenceInMinutes(to: afternoon) == 75)
    #expect(laterMorning.differenceInMinutes(to: morning) == -30)
    #expect(afternoon.differenceInMinutes(to: morning) == -75)

    let midnight = try #require(Time(hour: 0, minute: 0))
    let noon = try #require(Time(hour: 12, minute: 0))
    #expect(midnight.differenceInMinutes(to: noon) == 720)
    
    let sameTime = try #require(Time(hour: 15, minute: 30))
    #expect(sameTime.differenceInMinutes(to: sameTime) == 0)
  }

  // MARK: - Edge Cases

  @Test("Boundary value handling")
  func testBoundaryValues() throws {
    // Test edge of valid ranges
    let startOfDay = try #require(Time(hour: 0, minute: 0, second: 0))
    #expect(startOfDay.secondsOfDay == 0)

    let endOfDay = try #require(Time(hour: 23, minute: 59, second: 59))
    #expect(endOfDay.secondsOfDay == 86399)

    // Test with seconds as nil
    let noSecond = try #require(Time(hour: 12, minute: 30, second: nil))
    #expect(noSecond.secondsOfDay == 12 * 3600 + 30 * 60)
  }

  @Test("Cross-timezone time comparison")
  func testCrossTimezoneComparison() throws {
    let utcTime = try #require(Time(hour: 14, minute: 0, timeZone: TimeZone(identifier: "UTC")!))
    let localTime = try #require(Time(hour: 14, minute: 0, timeZone: .current))

    // Comparison is based on seconds of day, not actual wall-clock time
    #expect(utcTime == localTime)
    #expect(utcTime.secondsOfDay == localTime.secondsOfDay)
  }
}
