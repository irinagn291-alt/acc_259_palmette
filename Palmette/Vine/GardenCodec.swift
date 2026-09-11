import Foundation

/// Role: Vine. Preference keys. Snapshot is JSON Data under pmt.garden.v1. Demo is Simulator-only.
enum VineKey {
    static let snapshot = "pmt.garden.v1"
    static let backup = "pmt.garden.v1.backup"
    static let demo = "pmt.demo.v1"
}

/// Role: Vine. Codable GardenDocument. schemaVersion from 1. Domain types never encode themselves.
struct GardenDocument: Equatable, Sendable {
    var schemaVersion: Int
    var garden: Garden
}

/// Role: Vine. schemaVersion switch and garden ↔ JSON mapping. UserDefaults never sees Vine raw.
enum GardenCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ document: GardenDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(RootRecord.from(document))
    }

    static func decode(_ data: Data) throws -> GardenDocument {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return try decoder.decode(RootRecord.self, from: data).asDocument()
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    static func committed(from garden: Garden) -> GardenDocument {
        GardenDocument(schemaVersion: currentSchema, garden: garden.resolvingOpenVine())
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}

private struct RootRecord: Codable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var openVineID: UUID?
    var vines: [VineRecord]
    var pourDays: [PourDayRecord]

    static func from(_ document: GardenDocument) -> RootRecord {
        let garden = document.garden.resolvingOpenVine()
        let days = garden.poursByDay.keys.sorted().map { day in
            PourDayRecord(day: day.rawValue, pours: (garden.poursByDay[day] ?? []).map(PourRecord.init(pour:)))
        }
        return RootRecord(
            schemaVersion: GardenCodec.currentSchema,
            onboardingComplete: garden.onboardingComplete,
            openVineID: garden.openVineID,
            vines: garden.vines.map(VineRecord.init(vine:)),
            pourDays: days
        )
    }

    func asDocument() throws -> GardenDocument {
        var poursByDay: [TrellisDay: [Pour]] = [:]
        for record in pourDays {
            let day = TrellisDay(rawValue: record.day)
            poursByDay[day] = try record.pours.map { try $0.asPour(day: day) }
        }
        let garden = Garden(
            onboardingComplete: onboardingComplete,
            vines: try vines.map { try $0.asVine() },
            openVineID: openVineID,
            poursByDay: poursByDay
        )
        return GardenDocument(schemaVersion: schemaVersion, garden: garden.resolvingOpenVine())
    }
}

private struct VineRecord: Codable {
    var id: UUID
    var name: String
    var target: Double
    var vineSeed: Int
    var flush: Double
    var wood: Double
    var nodeMarks: [NodeMarkRecord]

    init(vine: Vine) {
        id = vine.id
        name = vine.name
        target = vine.target
        vineSeed = vine.vineSeed
        flush = vine.leader.flush.amount
        wood = vine.leader.wood.amount
        nodeMarks = vine.nodeMarks.map(NodeMarkRecord.init(mark:))
    }

    func asVine() throws -> Vine {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw GardenCodec.Failure.corrupt }
        guard target.isFinite, target > 0 else { throw GardenCodec.Failure.corrupt }
        guard flush.isFinite, flush >= 0, wood.isFinite, wood >= 0 else {
            throw GardenCodec.Failure.corrupt
        }
        return Vine(
            id: id,
            name: trimmed,
            target: target,
            vineSeed: vineSeed,
            leader: Leader(flush: Flush(amount: flush), wood: Wood(amount: wood)),
            nodeMarks: try nodeMarks.map { try $0.asMark() }
        )
    }
}

private struct NodeMarkRecord: Codable {
    var id: UUID
    var quartile: Double
    var woodAmount: Double
    var writtenUnix: Double

    init(mark: NodeMark) {
        id = mark.id
        quartile = mark.quartile
        woodAmount = mark.woodAmount
        writtenUnix = mark.writtenUnix
    }

    func asMark() throws -> NodeMark {
        guard CaneQuartile.parse(quartile) != nil,
              woodAmount.isFinite, woodAmount >= 0,
              writtenUnix.isFinite else {
            throw GardenCodec.Failure.corrupt
        }
        return NodeMark(id: id, quartile: quartile, woodAmount: woodAmount, writtenUnix: writtenUnix)
    }
}

private struct PourDayRecord: Codable {
    var day: Int
    var pours: [PourRecord]
}

private struct PourRecord: Codable {
    var id: UUID
    var vineID: UUID
    var amount: Double

    init(pour: Pour) {
        id = pour.id
        vineID = pour.vineID
        amount = pour.amount
    }

    func asPour(day: TrellisDay) throws -> Pour {
        guard amount.isFinite, amount > 0 else { throw GardenCodec.Failure.corrupt }
        return Pour(id: id, vineID: vineID, amount: amount, day: day)
    }
}
