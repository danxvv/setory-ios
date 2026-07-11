//
//  gymappTests.swift
//  gymappTests
//

import Testing
@testable import gymapp

struct SmokeTests {
    @Test func testTargetRuns() {
        #expect(ExerciseCategory.allCases.count == 2)
    }
}
