//
//  Equipment.swift
//  gymapp
//

import Foundation

/// Equipment an exercise is performed with. Raw values are the stable
/// strings emitted by the catalog transform (tools/catalog/transform.py);
/// they serialize into seed data and the AI suggestion API.
enum Equipment: String, Codable, CaseIterable, Sendable {
    case assisted
    case band
    case barbell
    case bodyWeight = "body_weight"
    case bosuBall = "bosu_ball"
    case cable
    case dumbbell
    case ellipticalMachine = "elliptical_machine"
    case ezBarbell = "ez_barbell"
    case hammer
    case kettlebell
    case leverageMachine = "leverage_machine"
    case medicineBall = "medicine_ball"
    case olympicBarbell = "olympic_barbell"
    case resistanceBand = "resistance_band"
    case roller
    case rope
    case skiergMachine = "skierg_machine"
    case sledMachine = "sled_machine"
    case smithMachine = "smith_machine"
    case stabilityBall = "stability_ball"
    case stationaryBike = "stationary_bike"
    case stepmillMachine = "stepmill_machine"
    case tire
    case trapBar = "trap_bar"
    case upperBodyErgometer = "upper_body_ergometer"
    case weighted
    case wheelRoller = "wheel_roller"

    var displayName: String {
        switch self {
        case .assisted: String(localized: "Assisted")
        case .band: String(localized: "Band")
        case .barbell: String(localized: "Barbell")
        case .bodyWeight: String(localized: "Body Weight")
        case .bosuBall: String(localized: "Bosu Ball")
        case .cable: String(localized: "Cable")
        case .dumbbell: String(localized: "Dumbbell")
        case .ellipticalMachine: String(localized: "Elliptical Machine")
        case .ezBarbell: String(localized: "EZ Barbell")
        case .hammer: String(localized: "Hammer Machine")
        case .kettlebell: String(localized: "Kettlebell")
        case .leverageMachine: String(localized: "Leverage Machine")
        case .medicineBall: String(localized: "Medicine Ball")
        case .olympicBarbell: String(localized: "Olympic Barbell")
        case .resistanceBand: String(localized: "Resistance Band")
        case .roller: String(localized: "Roller")
        case .rope: String(localized: "Rope")
        case .skiergMachine: String(localized: "SkiErg Machine")
        case .sledMachine: String(localized: "Sled Machine")
        case .smithMachine: String(localized: "Smith Machine")
        case .stabilityBall: String(localized: "Stability Ball")
        case .stationaryBike: String(localized: "Stationary Bike")
        case .stepmillMachine: String(localized: "Stepmill Machine")
        case .tire: String(localized: "Tire")
        case .trapBar: String(localized: "Trap Bar")
        case .upperBodyErgometer: String(localized: "Upper Body Ergometer")
        case .weighted: String(localized: "Weighted")
        case .wheelRoller: String(localized: "Wheel Roller")
        }
    }
}
