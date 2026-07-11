//
//  MonthCalendarView.swift
//  gymapp
//

import SwiftUI

/// Month-grid calendar header: month navigation, day selection,
/// saved-workout markers, and a today indicator.
struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    /// Start-of-day dates that have a saved workout session.
    let savedDays: Set<Date>

    @State private var month = MonthGrid(containing: .now)

    private var calendar: Calendar { month.calendar }

    var body: some View {
        VStack(spacing: 12) {
            header
            weekdayRow
            dayGrid
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var header: some View {
        HStack {
            Text(month.monthStart.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .contentTransition(.numericText())
                .animation(.default, value: month.monthStart)
            Spacer()
            HStack(spacing: 4) {
                Button {
                    month = month.previousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                Button {
                    month = month.nextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .font(.body.weight(.semibold))
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(month.orderedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(0..<month.leadingBlankCount, id: \.self) { _ in
                Color.clear.frame(height: 38)
            }
            ForEach(month.days, id: \.self) { day in
                dayCell(for: day)
            }
        }
    }

    private func dayCell(for day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        let hasWorkout = savedDays.contains(day)

        return Button {
            selectedDate = day
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.callout.weight(isToday ? .bold : .regular))
                    .monospacedDigit()
                Circle()
                    .fill(dotStyle(hasWorkout: hasWorkout, isSelected: isSelected))
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .foregroundStyle(isSelected ? .white : (isToday ? Color.accentColor : .primary))
            .background {
                if isSelected {
                    Circle().fill(.tint)
                        .frame(width: 36, height: 36)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("day-\(calendar.component(.day, from: day))")
        .accessibilityValue(hasWorkout ? String(localized: "workout saved") : "")
    }

    private func dotStyle(hasWorkout: Bool, isSelected: Bool) -> AnyShapeStyle {
        guard hasWorkout else { return AnyShapeStyle(.clear) }
        return isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.tint)
    }
}

#Preview {
    MonthCalendarView(
        selectedDate: .constant(.now),
        savedDays: [Calendar.current.startOfDay(for: .now)]
    )
    .padding()
}
