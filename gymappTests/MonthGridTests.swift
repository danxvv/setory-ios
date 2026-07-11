//
//  MonthGridTests.swift
//  gymappTests
//

import Foundation
import Testing
@testable import gymapp

struct MonthGridTests {
    /// Fixed calendar (gregorian, Monday-first, UTC) so results don't
    /// depend on the machine running the tests.
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test func monthStartAndDayCount() {
        let grid = MonthGrid(containing: date(2026, 7, 10), calendar: calendar)
        #expect(grid.monthStart == date(2026, 7, 1))
        #expect(grid.days.count == 31)
        #expect(grid.days.first == date(2026, 7, 1))
        #expect(grid.days.last == date(2026, 7, 31))
    }

    @Test func februaryLeapYear() {
        let grid = MonthGrid(containing: date(2028, 2, 15), calendar: calendar)
        #expect(grid.days.count == 29)

        let nonLeap = MonthGrid(containing: date(2026, 2, 15), calendar: calendar)
        #expect(nonLeap.days.count == 28)
    }

    @Test func leadingBlanksRespectFirstWeekday() {
        // July 1, 2026 is a Wednesday → 2 blanks in a Monday-first grid.
        let grid = MonthGrid(containing: date(2026, 7, 10), calendar: calendar)
        #expect(grid.leadingBlankCount == 2)

        // In a Sunday-first grid the same month has 3 blanks.
        var sundayFirst = calendar
        sundayFirst.firstWeekday = 1
        let sundayGrid = MonthGrid(containing: date(2026, 7, 10), calendar: sundayFirst)
        #expect(sundayGrid.leadingBlankCount == 3)

        // A month starting exactly on the first weekday has no blanks.
        // June 1, 2026 is a Monday.
        let june = MonthGrid(containing: date(2026, 6, 5), calendar: calendar)
        #expect(june.leadingBlankCount == 0)
    }

    @Test func monthNavigationCrossesYearBoundaries() {
        let january = MonthGrid(containing: date(2026, 1, 15), calendar: calendar)
        #expect(january.previousMonth().monthStart == date(2025, 12, 1))

        let december = MonthGrid(containing: date(2026, 12, 15), calendar: calendar)
        #expect(december.nextMonth().monthStart == date(2027, 1, 1))
    }

    @Test func daysAreStartOfDayNormalized() {
        let grid = MonthGrid(containing: date(2026, 7, 10), calendar: calendar)
        for day in grid.days {
            #expect(day == calendar.startOfDay(for: day))
        }
    }

    @Test func containsOnlyOwnMonth() {
        let grid = MonthGrid(containing: date(2026, 7, 10), calendar: calendar)
        #expect(grid.contains(date(2026, 7, 31)))
        #expect(!grid.contains(date(2026, 8, 1)))
        #expect(!grid.contains(date(2025, 7, 10)))
    }

    @Test func weekdaySymbolsMatchColumnOrder() {
        let grid = MonthGrid(containing: date(2026, 7, 10), calendar: calendar)
        // Monday-first: symbols rotate so index 0 is Monday.
        #expect(grid.orderedWeekdaySymbols.count == 7)
        #expect(grid.orderedWeekdaySymbols.first == calendar.veryShortWeekdaySymbols[1])
    }
}
