//
//  MonthCalendarView.swift
//  gymapp
//

import SwiftUI

/// Month-grid calendar header: month navigation, day selection,
/// saved-workout markers, and a today indicator.
struct MonthCalendarView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .callout) private var dayHeight = 44
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
        .gymCard()
    }

    private var header: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout())
        return layout {
            Text(month.monthStart.formatted(.dateTime.month(.wide).year()))
                .font(.title3.weight(.bold))
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .default, value: month.monthStart)
            Spacer()
            HStack(spacing: 4) {
                Button {
                    month = month.previousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                        .background(GymTheme.softAccent, in: Circle())
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Text("Previous month"))
                Button {
                    month = month.nextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                        .background(GymTheme.softAccent, in: Circle())
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Text("Next month"))
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
                Color.clear.frame(height: dayHeight)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Circle()
                    .fill(dotStyle(hasWorkout: hasWorkout, isSelected: isSelected))
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: dayHeight)
            .foregroundStyle(isSelected ? GymTheme.onAccent : (isToday ? Color.accentColor : .primary))
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14).fill(.tint)
                        .frame(maxWidth: 44)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 14).strokeBorder(Color.accentColor, lineWidth: 1)
                        .frame(maxWidth: 44)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("day-\(calendar.component(.day, from: day))")
        .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(hasWorkout ? String(localized: "workout saved") : "")
    }

    private func dotStyle(hasWorkout: Bool, isSelected: Bool) -> AnyShapeStyle {
        guard hasWorkout else { return AnyShapeStyle(.clear) }
        return isSelected ? AnyShapeStyle(GymTheme.onAccent) : AnyShapeStyle(.tint)
    }
}

#Preview {
    MonthCalendarView(
        selectedDate: .constant(.now),
        savedDays: [Calendar.current.startOfDay(for: .now)]
    )
    .padding()
}
