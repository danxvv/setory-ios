//
//  AboutView.swift
//  Setory
//
//  Licenses and attribution for the bundled exercise catalog. Showing the
//  Gym visual attribution is a redistribution requirement, not decoration.
//  License bodies stay in English (legal text, rendered verbatim).
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                Text(verbatim: "Setory")
                    .font(.title2.bold())
                Text("Every set tells a story.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Text(verbatim: ExerciseMediaStore.attribution)
                    .font(.body.weight(.medium))
                    .accessibilityIdentifier("about-attribution")
                Text(verbatim: "Exercise images and animations are © Gym visual and are redistributed with permission at 180×180 resolution. Reuse of the media is governed by Gym visual's Terms & Conditions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Exercise media")
            }

            Section {
                Text(verbatim: "Exercise data and instruction text come from the exercises-dataset project (github.com/hasaneyldrm/exercises-dataset), released under the MIT License.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(verbatim: """
                MIT License

                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                """)
                .font(.caption2)
                .foregroundStyle(.secondary)
            } header: {
                Text("Exercise data license")
            }
        }
        .setoryListStyle()
        .navigationTitle("About & Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
