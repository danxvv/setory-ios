import SwiftUI

/// Catalog rows use the available width for the name at accessibility sizes.
struct ExerciseRowContent: View {
    let exercise: Exercise
    var showsMuscles = true
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            ExerciseThumbnailView(exercise: exercise)
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.localizedName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if showsMuscles {
                    MuscleChips(muscles: exercise.primaryMuscles, emphasis: .primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
