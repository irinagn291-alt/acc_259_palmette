import Foundation

/// Role: Vine. Typed faults of plant, pour, pinch, and retract. Views map these; they never mutate the garden.
enum VineFault: Error, Equatable, Sendable {
    case invalidPour
    case invalidTarget
    case emptyName
    case unknownVine
}

/// Role: Vine. Recoverable load outcome. Never crash on a corrupt snapshot.
enum GardenWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}
