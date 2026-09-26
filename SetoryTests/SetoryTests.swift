//
//  SetoryTests.swift
//  SetoryTests
//

import Testing
@testable import Setory

struct SmokeTests {
    @Test func testTargetRuns() {
        #expect(ExerciseCategory.allCases.count == 2)
    }
}
