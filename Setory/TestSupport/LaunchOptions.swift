//
//  LaunchOptions.swift
//  Setory
//
//  The only place in the app that reads CommandLine.arguments. Parsing the
//  UI-test launch hooks once, into typed values, keeps the flags from leaking
//  into feature code — the photo match sheet used to sniff its own argument.
//
//  Debug-only: Release builds never see these hooks (see TestOverrides).
//

#if DEBUG

import Foundation

struct LaunchOptions: Equatable {
    /// Any `-uitest*` argument marks a UI-test launch. XCUITest waits for the
    /// app to quiesce after every event, so each navigation push, sheet, and
    /// tab switch would otherwise pay its full animation duration.
    var isUITestLaunch = false
    /// `-uitest-reset`: wipe user-generated data and restore a pristine catalog.
    var resetsStore = false
    /// `-uitest-seed`: insert the two known sessions.
    var seedsSessions = false
    /// `-uitest-offline-media`: disable the media store's network path.
    var disablesMediaNetwork = false
    /// The scenario from `-uitest-ai <scenario>` or
    /// `-uitest-photo-match <scenario>`: success | error | no-key.
    var aiScenario: String?
    /// `-uitest-photo-match`: also expose the bundled fixture image so tests
    /// never open the camera or the system photo picker.
    var exposesPhotoMatchFixture = false

    static let current = LaunchOptions(arguments: CommandLine.arguments)

    init() {}

    init(arguments: [String]) {
        isUITestLaunch = arguments.contains { $0.hasPrefix("-uitest") }
        resetsStore = arguments.contains("-uitest-reset")
        seedsSessions = arguments.contains("-uitest-seed")
        disablesMediaNetwork = arguments.contains("-uitest-offline-media")
        exposesPhotoMatchFixture = arguments.contains("-uitest-photo-match")
        // Either AI hook stubs the whole AI stack: both features share one key
        // store, so a test that stubs one must not leave the other reading the
        // real Keychain.
        aiScenario = Self.value(after: "-uitest-ai", in: arguments)
            ?? Self.value(after: "-uitest-photo-match", in: arguments)
    }

    /// The value following `flag`, e.g. "success" for `-uitest-ai success`.
    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }
}

#endif
