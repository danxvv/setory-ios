//
//  MonthGrid.swift
//  Setory
//

import Foundation

/// Pure date math backing the month calendar: which days a month contains
/// and how they align to the weekday columns. Keeps the view free of
/// `DateComponents` edge cases so this logic can be unit tested.
struct MonthGrid: Equatable {
    let calendar: Calendar
    /// First day of the displayed month, normalized to start-of-day.
    let monthStart: Date

    init(containing date: Date, calendar: Calendar = .current) {
        self.calendar = calendar
        let components = calendar.dateComponents([.year, .month], from: date)
        self.monthStart = calendar.date(from: components)!
    }

    /// Every day of the month as start-of-day dates, in order.
    var days: [Date] {
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    /// Empty cells before day 1 so the grid aligns with the weekday header,
    /// respecting the calendar's `firstWeekday`.
    var leadingBlankCount: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    /// Single-letter weekday symbols ordered to match the grid columns.
    var orderedWeekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    func previousMonth() -> MonthGrid {
        MonthGrid(containing: calendar.date(byAdding: .month, value: -1, to: monthStart)!, calendar: calendar)
    }

    func nextMonth() -> MonthGrid {
        MonthGrid(containing: calendar.date(byAdding: .month, value: 1, to: monthStart)!, calendar: calendar)
    }
}
