// Generated using the ObjectBox Swift Generator — https://objectbox.io
// DO NOT EDIT

// swiftlint:disable all
import ObjectBox
import Foundation

// MARK: - Entity metadata

extension CalendarEvent: ObjectBox.Entity {}
extension ClaudeSession: ObjectBox.Entity {}
extension ClipboardItem: ObjectBox.Entity {}
extension IndexedFile: ObjectBox.Entity {}
extension Organization: ObjectBox.Entity {}
extension Person: ObjectBox.Entity {}
extension ReminderItem: ObjectBox.Entity {}
extension ScreenshotItem: ObjectBox.Entity {}

extension CalendarEvent: ObjectBox.__EntityRelatable {
    internal typealias EntityType = CalendarEvent

    internal var _id: EntityId<CalendarEvent> {
        return EntityId<CalendarEvent>(self.id.value)
    }
}

extension CalendarEvent: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = CalendarEventBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static let entityInfo = ObjectBox.EntityInfo(name: "CalendarEvent", id: 5)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: CalendarEvent.self, id: 5, uid: 6919833175936901888)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 6340321579938560)
        try entityBuilder.addProperty(name: "key", type: PropertyType.string, flags: [.indexed, .indexHash, .unique], id: 2, uid: 9117455352410347008, indexId: 7, indexUid: 4265768837513913856)
        try entityBuilder.addProperty(name: "eventIdentifier", type: PropertyType.string, id: 3, uid: 560045078795004416)
        try entityBuilder.addProperty(name: "title", type: PropertyType.string, id: 4, uid: 4673998185124568832)
        try entityBuilder.addProperty(name: "start", type: PropertyType.date, id: 5, uid: 107204777144927488)
        try entityBuilder.addProperty(name: "end", type: PropertyType.date, id: 6, uid: 1316679142017617408)
        try entityBuilder.addProperty(name: "isAllDay", type: PropertyType.bool, id: 7, uid: 5893647343204772352)
        try entityBuilder.addProperty(name: "location", type: PropertyType.string, id: 8, uid: 5594545178443223552)
        try entityBuilder.addProperty(name: "notes", type: PropertyType.string, id: 9, uid: 971728511841935104)
        try entityBuilder.addProperty(name: "calendarName", type: PropertyType.string, id: 10, uid: 4802406996157490944)
        try entityBuilder.addProperty(name: "attendeesText", type: PropertyType.string, id: 11, uid: 5162016828406086400)
        try entityBuilder.addProperty(name: "meetingURL", type: PropertyType.string, id: 12, uid: 5783629648704615168)
        try entityBuilder.addProperty(name: "searchKey", type: PropertyType.string, id: 13, uid: 8107912353536613888)
        try entityBuilder.addToManyRelation(id: 1, uid: 8445630544122859008,
                                            targetId: 7, targetUid: 8143474250481410304)

        try entityBuilder.lastProperty(id: 13, uid: 8107912353536613888)
    }
}

extension CalendarEvent {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.id == myId }
    internal static var id: Property<CalendarEvent, Id, Id> { return Property<CalendarEvent, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.key.startsWith("X") }
    internal static var key: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.eventIdentifier.startsWith("X") }
    internal static var eventIdentifier: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 3, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.title.startsWith("X") }
    internal static var title: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 4, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.start > 1234 }
    internal static var start: Property<CalendarEvent, Date, Void> { return Property<CalendarEvent, Date, Void>(propertyId: 5, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.end > 1234 }
    internal static var end: Property<CalendarEvent, Date, Void> { return Property<CalendarEvent, Date, Void>(propertyId: 6, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.isAllDay == true }
    internal static var isAllDay: Property<CalendarEvent, Bool, Void> { return Property<CalendarEvent, Bool, Void>(propertyId: 7, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.location.startsWith("X") }
    internal static var location: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 8, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.notes.startsWith("X") }
    internal static var notes: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 9, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.calendarName.startsWith("X") }
    internal static var calendarName: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 10, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.attendeesText.startsWith("X") }
    internal static var attendeesText: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 11, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.meetingURL.startsWith("X") }
    internal static var meetingURL: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 12, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { CalendarEvent.searchKey.startsWith("X") }
    internal static var searchKey: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 13, isPrimaryKey: false) }
    /// Use `CalendarEvent.attendees` to refer to this ToMany relation property in queries,
    /// like when using `QueryBuilder.and(property:, conditions:)`.

    internal static var attendees: ToManyProperty<Person> { return ToManyProperty(.relationId(1)) }


    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == CalendarEvent {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<CalendarEvent, Id, Id> { return Property<CalendarEvent, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .key.startsWith("X") }

    internal static var key: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .eventIdentifier.startsWith("X") }

    internal static var eventIdentifier: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 3, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .title.startsWith("X") }

    internal static var title: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 4, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .start > 1234 }

    internal static var start: Property<CalendarEvent, Date, Void> { return Property<CalendarEvent, Date, Void>(propertyId: 5, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .end > 1234 }

    internal static var end: Property<CalendarEvent, Date, Void> { return Property<CalendarEvent, Date, Void>(propertyId: 6, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .isAllDay == true }

    internal static var isAllDay: Property<CalendarEvent, Bool, Void> { return Property<CalendarEvent, Bool, Void>(propertyId: 7, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .location.startsWith("X") }

    internal static var location: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 8, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .notes.startsWith("X") }

    internal static var notes: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 9, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .calendarName.startsWith("X") }

    internal static var calendarName: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 10, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .attendeesText.startsWith("X") }

    internal static var attendeesText: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 11, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .meetingURL.startsWith("X") }

    internal static var meetingURL: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 12, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .searchKey.startsWith("X") }

    internal static var searchKey: Property<CalendarEvent, String, Void> { return Property<CalendarEvent, String, Void>(propertyId: 13, isPrimaryKey: false) }

    /// Use `.attendees` to refer to this ToMany relation property in queries, like when using
    /// `QueryBuilder.and(property:, conditions:)`.

    internal static var attendees: ToManyProperty<Person> { return ToManyProperty(.relationId(1)) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `CalendarEvent.EntityBindingType`.
internal final class CalendarEventBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = CalendarEvent
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_key = propertyCollector.prepare(string: entity.key)
        let propertyOffset_eventIdentifier = propertyCollector.prepare(string: entity.eventIdentifier)
        let propertyOffset_title = propertyCollector.prepare(string: entity.title)
        let propertyOffset_location = propertyCollector.prepare(string: entity.location)
        let propertyOffset_notes = propertyCollector.prepare(string: entity.notes)
        let propertyOffset_calendarName = propertyCollector.prepare(string: entity.calendarName)
        let propertyOffset_attendeesText = propertyCollector.prepare(string: entity.attendeesText)
        let propertyOffset_meetingURL = propertyCollector.prepare(string: entity.meetingURL)
        let propertyOffset_searchKey = propertyCollector.prepare(string: entity.searchKey)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(entity.start, at: 2 + 2 * 5)
        propertyCollector.collect(entity.end, at: 2 + 2 * 6)
        propertyCollector.collect(entity.isAllDay, at: 2 + 2 * 7)
        propertyCollector.collect(dataOffset: propertyOffset_key, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_eventIdentifier, at: 2 + 2 * 3)
        propertyCollector.collect(dataOffset: propertyOffset_title, at: 2 + 2 * 4)
        propertyCollector.collect(dataOffset: propertyOffset_location, at: 2 + 2 * 8)
        propertyCollector.collect(dataOffset: propertyOffset_notes, at: 2 + 2 * 9)
        propertyCollector.collect(dataOffset: propertyOffset_calendarName, at: 2 + 2 * 10)
        propertyCollector.collect(dataOffset: propertyOffset_attendeesText, at: 2 + 2 * 11)
        propertyCollector.collect(dataOffset: propertyOffset_meetingURL, at: 2 + 2 * 12)
        propertyCollector.collect(dataOffset: propertyOffset_searchKey, at: 2 + 2 * 13)
    }

    internal func postPut(fromEntity entity: EntityType, id: ObjectBox.Id, store: ObjectBox.Store) throws {
        if entityId(of: entity) == 0 {  // New object was put? Attach relations now that we have an ID.
            let attendees = ToMany<Person>.relation(
                sourceId: EntityId<CalendarEvent>(id.value),
                targetBox: store.box(for: ToMany<Person>.ReferencedType.self),
                relationId: 1)
            if !entity.attendees.isEmpty {
                attendees.replace(entity.attendees)
            }
            entity.attendees = attendees
            try entity.attendees.applyToDb()
        }
    }
    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = CalendarEvent()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.key = entityReader.read(at: 2 + 2 * 2)
        entity.eventIdentifier = entityReader.read(at: 2 + 2 * 3)
        entity.title = entityReader.read(at: 2 + 2 * 4)
        entity.start = entityReader.read(at: 2 + 2 * 5)
        entity.end = entityReader.read(at: 2 + 2 * 6)
        entity.isAllDay = entityReader.read(at: 2 + 2 * 7)
        entity.location = entityReader.read(at: 2 + 2 * 8)
        entity.notes = entityReader.read(at: 2 + 2 * 9)
        entity.calendarName = entityReader.read(at: 2 + 2 * 10)
        entity.attendeesText = entityReader.read(at: 2 + 2 * 11)
        entity.meetingURL = entityReader.read(at: 2 + 2 * 12)
        entity.searchKey = entityReader.read(at: 2 + 2 * 13)

        entity.attendees = ToMany<Person>.relation(
            sourceId: EntityId<CalendarEvent>(entity.id.value),
            targetBox: store.box(for: ToMany<Person>.ReferencedType.self),
            relationId: 1)
        return entity
    }
}



extension ClaudeSession: ObjectBox.__EntityRelatable {
    internal typealias EntityType = ClaudeSession

    internal var _id: EntityId<ClaudeSession> {
        return EntityId<ClaudeSession>(self.id.value)
    }
}

extension ClaudeSession: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = ClaudeSessionBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static let entityInfo = ObjectBox.EntityInfo(name: "ClaudeSession", id: 4)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: ClaudeSession.self, id: 4, uid: 7740019210499360512)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 5828541432430034176)
        try entityBuilder.addProperty(name: "sessionId", type: PropertyType.string, flags: [.indexed, .indexHash, .unique], id: 2, uid: 1332224042699151616, indexId: 5, indexUid: 7263469940184939264)
        try entityBuilder.addProperty(name: "filePath", type: PropertyType.string, id: 3, uid: 9027989477286739712)
        try entityBuilder.addProperty(name: "projectPath", type: PropertyType.string, id: 4, uid: 7269378526588986368)
        try entityBuilder.addProperty(name: "title", type: PropertyType.string, id: 5, uid: 2485896983221711872)
        try entityBuilder.addProperty(name: "firstPrompt", type: PropertyType.string, id: 6, uid: 7459805678547962112)
        try entityBuilder.addProperty(name: "prompts", type: PropertyType.string, id: 7, uid: 3529577330505040384)
        try entityBuilder.addProperty(name: "answers", type: PropertyType.string, id: 8, uid: 835048620571630592)
        try entityBuilder.addProperty(name: "gitBranch", type: PropertyType.string, id: 9, uid: 7707939616994536192)
        try entityBuilder.addProperty(name: "startedAt", type: PropertyType.date, id: 10, uid: 5413418402635660544)
        try entityBuilder.addProperty(name: "updatedAt", type: PropertyType.date, id: 11, uid: 6063907474645697536)
        try entityBuilder.addProperty(name: "fileSize", type: PropertyType.long, id: 12, uid: 5239862192315572992)
        try entityBuilder.addProperty(name: "promptCount", type: PropertyType.long, id: 13, uid: 8519127457381072128)
        try entityBuilder.addProperty(name: "searchKey", type: PropertyType.string, id: 14, uid: 8430881029080297728)
        try entityBuilder.addProperty(name: "vector", type: PropertyType.floatVector, flags: [.indexed], id: 15, uid: 590212604363096832, indexId: 6, indexUid: 1091072165143365632)
            .hnswParams(dimensions: 384, neighborsPerNode: nil, indexingSearchCount: nil, flags: nil, distanceType: HnswDistanceType.cosine, reparationBacklinkProbability: nil, vectorCacheHintSizeKB: nil)

        try entityBuilder.lastProperty(id: 15, uid: 590212604363096832)
    }
}

extension ClaudeSession {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.id == myId }
    internal static var id: Property<ClaudeSession, Id, Id> { return Property<ClaudeSession, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.sessionId.startsWith("X") }
    internal static var sessionId: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.filePath.startsWith("X") }
    internal static var filePath: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 3, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.projectPath.startsWith("X") }
    internal static var projectPath: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 4, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.title.startsWith("X") }
    internal static var title: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 5, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.firstPrompt.startsWith("X") }
    internal static var firstPrompt: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 6, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.prompts.startsWith("X") }
    internal static var prompts: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 7, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.answers.startsWith("X") }
    internal static var answers: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 8, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.gitBranch.startsWith("X") }
    internal static var gitBranch: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 9, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.startedAt > 1234 }
    internal static var startedAt: Property<ClaudeSession, Date, Void> { return Property<ClaudeSession, Date, Void>(propertyId: 10, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.updatedAt > 1234 }
    internal static var updatedAt: Property<ClaudeSession, Date, Void> { return Property<ClaudeSession, Date, Void>(propertyId: 11, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.fileSize > 1234 }
    internal static var fileSize: Property<ClaudeSession, Int64, Void> { return Property<ClaudeSession, Int64, Void>(propertyId: 12, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.promptCount > 1234 }
    internal static var promptCount: Property<ClaudeSession, Int, Void> { return Property<ClaudeSession, Int, Void>(propertyId: 13, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.searchKey.startsWith("X") }
    internal static var searchKey: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 14, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClaudeSession.vector.isGreaterThan(value) }
    internal static var vector: Property<ClaudeSession, HnswIndexPropertyType, Void> { return Property<ClaudeSession, HnswIndexPropertyType, Void>(propertyId: 15, isPrimaryKey: false) }

    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == ClaudeSession {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<ClaudeSession, Id, Id> { return Property<ClaudeSession, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .sessionId.startsWith("X") }

    internal static var sessionId: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .filePath.startsWith("X") }

    internal static var filePath: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 3, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .projectPath.startsWith("X") }

    internal static var projectPath: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 4, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .title.startsWith("X") }

    internal static var title: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 5, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .firstPrompt.startsWith("X") }

    internal static var firstPrompt: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 6, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .prompts.startsWith("X") }

    internal static var prompts: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 7, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .answers.startsWith("X") }

    internal static var answers: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 8, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .gitBranch.startsWith("X") }

    internal static var gitBranch: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 9, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .startedAt > 1234 }

    internal static var startedAt: Property<ClaudeSession, Date, Void> { return Property<ClaudeSession, Date, Void>(propertyId: 10, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .updatedAt > 1234 }

    internal static var updatedAt: Property<ClaudeSession, Date, Void> { return Property<ClaudeSession, Date, Void>(propertyId: 11, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .fileSize > 1234 }

    internal static var fileSize: Property<ClaudeSession, Int64, Void> { return Property<ClaudeSession, Int64, Void>(propertyId: 12, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .promptCount > 1234 }

    internal static var promptCount: Property<ClaudeSession, Int, Void> { return Property<ClaudeSession, Int, Void>(propertyId: 13, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .searchKey.startsWith("X") }

    internal static var searchKey: Property<ClaudeSession, String, Void> { return Property<ClaudeSession, String, Void>(propertyId: 14, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .vector.isNotNil() }

    internal static var vector: Property<ClaudeSession, HnswIndexPropertyType, Void> { return Property<ClaudeSession, HnswIndexPropertyType, Void>(propertyId: 15, isPrimaryKey: false) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `ClaudeSession.EntityBindingType`.
internal final class ClaudeSessionBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = ClaudeSession
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_sessionId = propertyCollector.prepare(string: entity.sessionId)
        let propertyOffset_filePath = propertyCollector.prepare(string: entity.filePath)
        let propertyOffset_projectPath = propertyCollector.prepare(string: entity.projectPath)
        let propertyOffset_title = propertyCollector.prepare(string: entity.title)
        let propertyOffset_firstPrompt = propertyCollector.prepare(string: entity.firstPrompt)
        let propertyOffset_prompts = propertyCollector.prepare(string: entity.prompts)
        let propertyOffset_answers = propertyCollector.prepare(string: entity.answers)
        let propertyOffset_gitBranch = propertyCollector.prepare(string: entity.gitBranch)
        let propertyOffset_searchKey = propertyCollector.prepare(string: entity.searchKey)
        let propertyOffset_vector = propertyCollector.prepare(values: entity.vector)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(entity.startedAt, at: 2 + 2 * 10)
        propertyCollector.collect(entity.updatedAt, at: 2 + 2 * 11)
        propertyCollector.collect(entity.fileSize, at: 2 + 2 * 12)
        propertyCollector.collect(entity.promptCount, at: 2 + 2 * 13)
        propertyCollector.collect(dataOffset: propertyOffset_sessionId, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_filePath, at: 2 + 2 * 3)
        propertyCollector.collect(dataOffset: propertyOffset_projectPath, at: 2 + 2 * 4)
        propertyCollector.collect(dataOffset: propertyOffset_title, at: 2 + 2 * 5)
        propertyCollector.collect(dataOffset: propertyOffset_firstPrompt, at: 2 + 2 * 6)
        propertyCollector.collect(dataOffset: propertyOffset_prompts, at: 2 + 2 * 7)
        propertyCollector.collect(dataOffset: propertyOffset_answers, at: 2 + 2 * 8)
        propertyCollector.collect(dataOffset: propertyOffset_gitBranch, at: 2 + 2 * 9)
        propertyCollector.collect(dataOffset: propertyOffset_searchKey, at: 2 + 2 * 14)
        propertyCollector.collect(dataOffset: propertyOffset_vector, at: 2 + 2 * 15)
    }

    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = ClaudeSession()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.sessionId = entityReader.read(at: 2 + 2 * 2)
        entity.filePath = entityReader.read(at: 2 + 2 * 3)
        entity.projectPath = entityReader.read(at: 2 + 2 * 4)
        entity.title = entityReader.read(at: 2 + 2 * 5)
        entity.firstPrompt = entityReader.read(at: 2 + 2 * 6)
        entity.prompts = entityReader.read(at: 2 + 2 * 7)
        entity.answers = entityReader.read(at: 2 + 2 * 8)
        entity.gitBranch = entityReader.read(at: 2 + 2 * 9)
        entity.startedAt = entityReader.read(at: 2 + 2 * 10)
        entity.updatedAt = entityReader.read(at: 2 + 2 * 11)
        entity.fileSize = entityReader.read(at: 2 + 2 * 12)
        entity.promptCount = entityReader.read(at: 2 + 2 * 13)
        entity.searchKey = entityReader.read(at: 2 + 2 * 14)
        entity.vector = entityReader.read(at: 2 + 2 * 15)

        return entity
    }
}



extension ClipboardItem: ObjectBox.__EntityRelatable {
    internal typealias EntityType = ClipboardItem

    internal var _id: EntityId<ClipboardItem> {
        return EntityId<ClipboardItem>(self.id.value)
    }
}

extension ClipboardItem: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = ClipboardItemBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static let entityInfo = ObjectBox.EntityInfo(name: "ClipboardItem", id: 2)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: ClipboardItem.self, id: 2, uid: 7774308101723573760)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 5525084147079463936)
        try entityBuilder.addProperty(name: "kind", type: PropertyType.string, id: 2, uid: 5856456557581124352)
        try entityBuilder.addProperty(name: "text", type: PropertyType.string, id: 3, uid: 639250747536494848)
        try entityBuilder.addProperty(name: "imagePath", type: PropertyType.string, id: 4, uid: 642096632350127872)
        try entityBuilder.addProperty(name: "sourceAppName", type: PropertyType.string, id: 5, uid: 1452489389586473984)
        try entityBuilder.addProperty(name: "sourceAppPath", type: PropertyType.string, id: 6, uid: 7378503980804151552)
        try entityBuilder.addProperty(name: "createdAt", type: PropertyType.date, id: 7, uid: 3888016770695037696)
        try entityBuilder.addProperty(name: "isPinned", type: PropertyType.bool, id: 8, uid: 8773240087853904896)
        try entityBuilder.addProperty(name: "searchKey", type: PropertyType.string, id: 9, uid: 2042859179706950400)

        try entityBuilder.lastProperty(id: 9, uid: 2042859179706950400)
    }
}

extension ClipboardItem {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClipboardItem.id == myId }
    internal static var id: Property<ClipboardItem, Id, Id> { return Property<ClipboardItem, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClipboardItem.kind.startsWith("X") }
    internal static var kind: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClipboardItem.text.startsWith("X") }
    internal static var text: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 3, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClipboardItem.imagePath.startsWith("X") }
    internal static var imagePath: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 4, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClipboardItem.sourceAppName.startsWith("X") }
    internal static var sourceAppName: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 5, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClipboardItem.sourceAppPath.startsWith("X") }
    internal static var sourceAppPath: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 6, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClipboardItem.createdAt > 1234 }
    internal static var createdAt: Property<ClipboardItem, Date, Void> { return Property<ClipboardItem, Date, Void>(propertyId: 7, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClipboardItem.isPinned == true }
    internal static var isPinned: Property<ClipboardItem, Bool, Void> { return Property<ClipboardItem, Bool, Void>(propertyId: 8, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ClipboardItem.searchKey.startsWith("X") }
    internal static var searchKey: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 9, isPrimaryKey: false) }

    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == ClipboardItem {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<ClipboardItem, Id, Id> { return Property<ClipboardItem, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .kind.startsWith("X") }

    internal static var kind: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .text.startsWith("X") }

    internal static var text: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 3, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .imagePath.startsWith("X") }

    internal static var imagePath: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 4, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .sourceAppName.startsWith("X") }

    internal static var sourceAppName: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 5, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .sourceAppPath.startsWith("X") }

    internal static var sourceAppPath: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 6, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .createdAt > 1234 }

    internal static var createdAt: Property<ClipboardItem, Date, Void> { return Property<ClipboardItem, Date, Void>(propertyId: 7, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .isPinned == true }

    internal static var isPinned: Property<ClipboardItem, Bool, Void> { return Property<ClipboardItem, Bool, Void>(propertyId: 8, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .searchKey.startsWith("X") }

    internal static var searchKey: Property<ClipboardItem, String, Void> { return Property<ClipboardItem, String, Void>(propertyId: 9, isPrimaryKey: false) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `ClipboardItem.EntityBindingType`.
internal final class ClipboardItemBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = ClipboardItem
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_kind = propertyCollector.prepare(string: entity.kind)
        let propertyOffset_text = propertyCollector.prepare(string: entity.text)
        let propertyOffset_imagePath = propertyCollector.prepare(string: entity.imagePath)
        let propertyOffset_sourceAppName = propertyCollector.prepare(string: entity.sourceAppName)
        let propertyOffset_sourceAppPath = propertyCollector.prepare(string: entity.sourceAppPath)
        let propertyOffset_searchKey = propertyCollector.prepare(string: entity.searchKey)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(entity.createdAt, at: 2 + 2 * 7)
        propertyCollector.collect(entity.isPinned, at: 2 + 2 * 8)
        propertyCollector.collect(dataOffset: propertyOffset_kind, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_text, at: 2 + 2 * 3)
        propertyCollector.collect(dataOffset: propertyOffset_imagePath, at: 2 + 2 * 4)
        propertyCollector.collect(dataOffset: propertyOffset_sourceAppName, at: 2 + 2 * 5)
        propertyCollector.collect(dataOffset: propertyOffset_sourceAppPath, at: 2 + 2 * 6)
        propertyCollector.collect(dataOffset: propertyOffset_searchKey, at: 2 + 2 * 9)
    }

    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = ClipboardItem()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.kind = entityReader.read(at: 2 + 2 * 2)
        entity.text = entityReader.read(at: 2 + 2 * 3)
        entity.imagePath = entityReader.read(at: 2 + 2 * 4)
        entity.sourceAppName = entityReader.read(at: 2 + 2 * 5)
        entity.sourceAppPath = entityReader.read(at: 2 + 2 * 6)
        entity.createdAt = entityReader.read(at: 2 + 2 * 7)
        entity.isPinned = entityReader.read(at: 2 + 2 * 8)
        entity.searchKey = entityReader.read(at: 2 + 2 * 9)

        return entity
    }
}



extension IndexedFile: ObjectBox.__EntityRelatable {
    internal typealias EntityType = IndexedFile

    internal var _id: EntityId<IndexedFile> {
        return EntityId<IndexedFile>(self.id.value)
    }
}

extension IndexedFile: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = IndexedFileBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static let entityInfo = ObjectBox.EntityInfo(name: "IndexedFile", id: 1)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: IndexedFile.self, id: 1, uid: 3632320260303897600)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 2093573065777810944)
        try entityBuilder.addProperty(name: "path", type: PropertyType.string, flags: [.indexed, .indexHash, .unique], id: 2, uid: 4010168664377497856, indexId: 1, indexUid: 6359226147775625216)
        try entityBuilder.addProperty(name: "name", type: PropertyType.string, id: 3, uid: 7998241056123088640)
        try entityBuilder.addProperty(name: "fileExtension", type: PropertyType.string, id: 4, uid: 8796098250286961408)
        try entityBuilder.addProperty(name: "size", type: PropertyType.long, id: 5, uid: 5907123611409522688)
        try entityBuilder.addProperty(name: "modifiedAt", type: PropertyType.date, id: 6, uid: 3435642203369535744)
        try entityBuilder.addProperty(name: "indexedAt", type: PropertyType.date, id: 7, uid: 5283100687172449024)
        try entityBuilder.addProperty(name: "summary", type: PropertyType.string, id: 8, uid: 7628820291782344960)
        try entityBuilder.addProperty(name: "tags", type: PropertyType.string, id: 9, uid: 9122294828608410112)
        try entityBuilder.addProperty(name: "sourceURL", type: PropertyType.string, id: 18, uid: 1272791285598431744)
        try entityBuilder.addProperty(name: "lastUsedAt", type: PropertyType.date, id: 19, uid: 1995752071660332288)
        try entityBuilder.addProperty(name: "useCount", type: PropertyType.long, id: 20, uid: 2829248761452263424)
        try entityBuilder.addProperty(name: "finderTags", type: PropertyType.string, id: 21, uid: 4886159558870635264)
        try entityBuilder.addProperty(name: "keywords", type: PropertyType.string, id: 15, uid: 3115580015656150784)
        try entityBuilder.addProperty(name: "summaryVersion", type: PropertyType.long, id: 16, uid: 7446600369040747008)
        try entityBuilder.addProperty(name: "status", type: PropertyType.string, id: 10, uid: 5611077474044799232)
        try entityBuilder.addProperty(name: "errorMessage", type: PropertyType.string, id: 11, uid: 7156838880195154176)
        try entityBuilder.addProperty(name: "searchKey", type: PropertyType.string, id: 14, uid: 913336607183202304)
        try entityBuilder.addProperty(name: "vector", type: PropertyType.floatVector, flags: [.indexed], id: 17, uid: 4374172112284725248, indexId: 4, indexUid: 6625996782417470464)
            .hnswParams(dimensions: 384, neighborsPerNode: nil, indexingSearchCount: nil, flags: nil, distanceType: HnswDistanceType.cosine, reparationBacklinkProbability: nil, vectorCacheHintSizeKB: nil)
        try entityBuilder.addProperty(name: "embeddingModel", type: PropertyType.string, id: 13, uid: 6259217832621521664)
        try entityBuilder.addToManyRelation(id: 2, uid: 6216723500342444544,
                                            targetId: 7, targetUid: 8143474250481410304)
        try entityBuilder.addToManyRelation(id: 3, uid: 8094558302600375296,
                                            targetId: 6, targetUid: 8095144562327525120)

        try entityBuilder.lastProperty(id: 21, uid: 4886159558870635264)
    }
}

extension IndexedFile {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.id == myId }
    internal static var id: Property<IndexedFile, Id, Id> { return Property<IndexedFile, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.path.startsWith("X") }
    internal static var path: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.name.startsWith("X") }
    internal static var name: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 3, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.fileExtension.startsWith("X") }
    internal static var fileExtension: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 4, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.size > 1234 }
    internal static var size: Property<IndexedFile, Int64, Void> { return Property<IndexedFile, Int64, Void>(propertyId: 5, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.modifiedAt > 1234 }
    internal static var modifiedAt: Property<IndexedFile, Date, Void> { return Property<IndexedFile, Date, Void>(propertyId: 6, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.indexedAt > 1234 }
    internal static var indexedAt: Property<IndexedFile, Date?, Void> { return Property<IndexedFile, Date?, Void>(propertyId: 7, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.summary.startsWith("X") }
    internal static var summary: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 8, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.tags.startsWith("X") }
    internal static var tags: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 9, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.sourceURL.startsWith("X") }
    internal static var sourceURL: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 18, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.lastUsedAt > 1234 }
    internal static var lastUsedAt: Property<IndexedFile, Date?, Void> { return Property<IndexedFile, Date?, Void>(propertyId: 19, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.useCount > 1234 }
    internal static var useCount: Property<IndexedFile, Int, Void> { return Property<IndexedFile, Int, Void>(propertyId: 20, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.finderTags.startsWith("X") }
    internal static var finderTags: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 21, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.keywords.startsWith("X") }
    internal static var keywords: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 15, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.summaryVersion > 1234 }
    internal static var summaryVersion: Property<IndexedFile, Int, Void> { return Property<IndexedFile, Int, Void>(propertyId: 16, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.status.startsWith("X") }
    internal static var status: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 10, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.errorMessage.startsWith("X") }
    internal static var errorMessage: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 11, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.searchKey.startsWith("X") }
    internal static var searchKey: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 14, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.vector.isGreaterThan(value) }
    internal static var vector: Property<IndexedFile, HnswIndexPropertyType, Void> { return Property<IndexedFile, HnswIndexPropertyType, Void>(propertyId: 17, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { IndexedFile.embeddingModel.startsWith("X") }
    internal static var embeddingModel: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 13, isPrimaryKey: false) }
    /// Use `IndexedFile.people` to refer to this ToMany relation property in queries,
    /// like when using `QueryBuilder.and(property:, conditions:)`.

    internal static var people: ToManyProperty<Person> { return ToManyProperty(.relationId(2)) }

    /// Use `IndexedFile.organizations` to refer to this ToMany relation property in queries,
    /// like when using `QueryBuilder.and(property:, conditions:)`.

    internal static var organizations: ToManyProperty<Organization> { return ToManyProperty(.relationId(3)) }


    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == IndexedFile {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<IndexedFile, Id, Id> { return Property<IndexedFile, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .path.startsWith("X") }

    internal static var path: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .name.startsWith("X") }

    internal static var name: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 3, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .fileExtension.startsWith("X") }

    internal static var fileExtension: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 4, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .size > 1234 }

    internal static var size: Property<IndexedFile, Int64, Void> { return Property<IndexedFile, Int64, Void>(propertyId: 5, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .modifiedAt > 1234 }

    internal static var modifiedAt: Property<IndexedFile, Date, Void> { return Property<IndexedFile, Date, Void>(propertyId: 6, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .indexedAt > 1234 }

    internal static var indexedAt: Property<IndexedFile, Date?, Void> { return Property<IndexedFile, Date?, Void>(propertyId: 7, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .summary.startsWith("X") }

    internal static var summary: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 8, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .tags.startsWith("X") }

    internal static var tags: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 9, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .sourceURL.startsWith("X") }

    internal static var sourceURL: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 18, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .lastUsedAt > 1234 }

    internal static var lastUsedAt: Property<IndexedFile, Date?, Void> { return Property<IndexedFile, Date?, Void>(propertyId: 19, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .useCount > 1234 }

    internal static var useCount: Property<IndexedFile, Int, Void> { return Property<IndexedFile, Int, Void>(propertyId: 20, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .finderTags.startsWith("X") }

    internal static var finderTags: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 21, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .keywords.startsWith("X") }

    internal static var keywords: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 15, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .summaryVersion > 1234 }

    internal static var summaryVersion: Property<IndexedFile, Int, Void> { return Property<IndexedFile, Int, Void>(propertyId: 16, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .status.startsWith("X") }

    internal static var status: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 10, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .errorMessage.startsWith("X") }

    internal static var errorMessage: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 11, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .searchKey.startsWith("X") }

    internal static var searchKey: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 14, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .vector.isNotNil() }

    internal static var vector: Property<IndexedFile, HnswIndexPropertyType, Void> { return Property<IndexedFile, HnswIndexPropertyType, Void>(propertyId: 17, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .embeddingModel.startsWith("X") }

    internal static var embeddingModel: Property<IndexedFile, String, Void> { return Property<IndexedFile, String, Void>(propertyId: 13, isPrimaryKey: false) }

    /// Use `.people` to refer to this ToMany relation property in queries, like when using
    /// `QueryBuilder.and(property:, conditions:)`.

    internal static var people: ToManyProperty<Person> { return ToManyProperty(.relationId(2)) }

    /// Use `.organizations` to refer to this ToMany relation property in queries, like when using
    /// `QueryBuilder.and(property:, conditions:)`.

    internal static var organizations: ToManyProperty<Organization> { return ToManyProperty(.relationId(3)) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `IndexedFile.EntityBindingType`.
internal final class IndexedFileBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = IndexedFile
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_path = propertyCollector.prepare(string: entity.path)
        let propertyOffset_name = propertyCollector.prepare(string: entity.name)
        let propertyOffset_fileExtension = propertyCollector.prepare(string: entity.fileExtension)
        let propertyOffset_summary = propertyCollector.prepare(string: entity.summary)
        let propertyOffset_tags = propertyCollector.prepare(string: entity.tags)
        let propertyOffset_sourceURL = propertyCollector.prepare(string: entity.sourceURL)
        let propertyOffset_finderTags = propertyCollector.prepare(string: entity.finderTags)
        let propertyOffset_keywords = propertyCollector.prepare(string: entity.keywords)
        let propertyOffset_status = propertyCollector.prepare(string: entity.status)
        let propertyOffset_errorMessage = propertyCollector.prepare(string: entity.errorMessage)
        let propertyOffset_searchKey = propertyCollector.prepare(string: entity.searchKey)
        let propertyOffset_vector = propertyCollector.prepare(values: entity.vector)
        let propertyOffset_embeddingModel = propertyCollector.prepare(string: entity.embeddingModel)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(entity.size, at: 2 + 2 * 5)
        propertyCollector.collect(entity.modifiedAt, at: 2 + 2 * 6)
        propertyCollector.collect(entity.indexedAt, at: 2 + 2 * 7)
        propertyCollector.collect(entity.lastUsedAt, at: 2 + 2 * 19)
        propertyCollector.collect(entity.useCount, at: 2 + 2 * 20)
        propertyCollector.collect(entity.summaryVersion, at: 2 + 2 * 16)
        propertyCollector.collect(dataOffset: propertyOffset_path, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_name, at: 2 + 2 * 3)
        propertyCollector.collect(dataOffset: propertyOffset_fileExtension, at: 2 + 2 * 4)
        propertyCollector.collect(dataOffset: propertyOffset_summary, at: 2 + 2 * 8)
        propertyCollector.collect(dataOffset: propertyOffset_tags, at: 2 + 2 * 9)
        propertyCollector.collect(dataOffset: propertyOffset_sourceURL, at: 2 + 2 * 18)
        propertyCollector.collect(dataOffset: propertyOffset_finderTags, at: 2 + 2 * 21)
        propertyCollector.collect(dataOffset: propertyOffset_keywords, at: 2 + 2 * 15)
        propertyCollector.collect(dataOffset: propertyOffset_status, at: 2 + 2 * 10)
        propertyCollector.collect(dataOffset: propertyOffset_errorMessage, at: 2 + 2 * 11)
        propertyCollector.collect(dataOffset: propertyOffset_searchKey, at: 2 + 2 * 14)
        propertyCollector.collect(dataOffset: propertyOffset_vector, at: 2 + 2 * 17)
        propertyCollector.collect(dataOffset: propertyOffset_embeddingModel, at: 2 + 2 * 13)
    }

    internal func postPut(fromEntity entity: EntityType, id: ObjectBox.Id, store: ObjectBox.Store) throws {
        if entityId(of: entity) == 0 {  // New object was put? Attach relations now that we have an ID.
            let people = ToMany<Person>.relation(
                sourceId: EntityId<IndexedFile>(id.value),
                targetBox: store.box(for: ToMany<Person>.ReferencedType.self),
                relationId: 2)
            if !entity.people.isEmpty {
                people.replace(entity.people)
            }
            entity.people = people
            let organizations = ToMany<Organization>.relation(
                sourceId: EntityId<IndexedFile>(id.value),
                targetBox: store.box(for: ToMany<Organization>.ReferencedType.self),
                relationId: 3)
            if !entity.organizations.isEmpty {
                organizations.replace(entity.organizations)
            }
            entity.organizations = organizations
            try entity.people.applyToDb()
            try entity.organizations.applyToDb()
        }
    }
    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = IndexedFile()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.path = entityReader.read(at: 2 + 2 * 2)
        entity.name = entityReader.read(at: 2 + 2 * 3)
        entity.fileExtension = entityReader.read(at: 2 + 2 * 4)
        entity.size = entityReader.read(at: 2 + 2 * 5)
        entity.modifiedAt = entityReader.read(at: 2 + 2 * 6)
        entity.indexedAt = entityReader.read(at: 2 + 2 * 7)
        entity.summary = entityReader.read(at: 2 + 2 * 8)
        entity.tags = entityReader.read(at: 2 + 2 * 9)
        entity.sourceURL = entityReader.read(at: 2 + 2 * 18)
        entity.lastUsedAt = entityReader.read(at: 2 + 2 * 19)
        entity.useCount = entityReader.read(at: 2 + 2 * 20)
        entity.finderTags = entityReader.read(at: 2 + 2 * 21)
        entity.keywords = entityReader.read(at: 2 + 2 * 15)
        entity.summaryVersion = entityReader.read(at: 2 + 2 * 16)
        entity.status = entityReader.read(at: 2 + 2 * 10)
        entity.errorMessage = entityReader.read(at: 2 + 2 * 11)
        entity.searchKey = entityReader.read(at: 2 + 2 * 14)
        entity.vector = entityReader.read(at: 2 + 2 * 17)
        entity.embeddingModel = entityReader.read(at: 2 + 2 * 13)

        entity.people = ToMany<Person>.relation(
            sourceId: EntityId<IndexedFile>(entity.id.value),
            targetBox: store.box(for: ToMany<Person>.ReferencedType.self),
            relationId: 2)
        entity.organizations = ToMany<Organization>.relation(
            sourceId: EntityId<IndexedFile>(entity.id.value),
            targetBox: store.box(for: ToMany<Organization>.ReferencedType.self),
            relationId: 3)
        return entity
    }
}



extension Organization: ObjectBox.__EntityRelatable {
    internal typealias EntityType = Organization

    internal var _id: EntityId<Organization> {
        return EntityId<Organization>(self.id.value)
    }
}

extension Organization: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = OrganizationBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static let entityInfo = ObjectBox.EntityInfo(name: "Organization", id: 6)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: Organization.self, id: 6, uid: 8095144562327525120)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 4147642652209128704)
        try entityBuilder.addProperty(name: "name", type: PropertyType.string, id: 2, uid: 7965929693366613760)
        try entityBuilder.addProperty(name: "nameKey", type: PropertyType.string, flags: [.indexed, .indexHash], id: 3, uid: 1278817180328204800, indexId: 8, indexUid: 1737951767919355392)
        try entityBuilder.addProperty(name: "kind", type: PropertyType.string, id: 5, uid: 4751092564873672960)
        try entityBuilder.addProperty(name: "aliases", type: PropertyType.string, id: 6, uid: 4855080888374894848)
        try entityBuilder.addProperty(name: "searchKey", type: PropertyType.string, id: 4, uid: 1463770356691653632)

        try entityBuilder.lastProperty(id: 6, uid: 4855080888374894848)
    }
}

extension Organization {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Organization.id == myId }
    internal static var id: Property<Organization, Id, Id> { return Property<Organization, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Organization.name.startsWith("X") }
    internal static var name: Property<Organization, String, Void> { return Property<Organization, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Organization.nameKey.startsWith("X") }
    internal static var nameKey: Property<Organization, String, Void> { return Property<Organization, String, Void>(propertyId: 3, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Organization.kind.startsWith("X") }
    internal static var kind: Property<Organization, String, Void> { return Property<Organization, String, Void>(propertyId: 5, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Organization.aliases.startsWith("X") }
    internal static var aliases: Property<Organization, String, Void> { return Property<Organization, String, Void>(propertyId: 6, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Organization.searchKey.startsWith("X") }
    internal static var searchKey: Property<Organization, String, Void> { return Property<Organization, String, Void>(propertyId: 4, isPrimaryKey: false) }
    /// Use `Organization.files` to refer to this ToMany relation property in queries,
    /// like when using `QueryBuilder.and(property:, conditions:)`.

    internal static var files: ToManyProperty<IndexedFile> { return ToManyProperty(.backlinkRelationId(3)) }


    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == Organization {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<Organization, Id, Id> { return Property<Organization, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .name.startsWith("X") }

    internal static var name: Property<Organization, String, Void> { return Property<Organization, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .nameKey.startsWith("X") }

    internal static var nameKey: Property<Organization, String, Void> { return Property<Organization, String, Void>(propertyId: 3, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .kind.startsWith("X") }

    internal static var kind: Property<Organization, String, Void> { return Property<Organization, String, Void>(propertyId: 5, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .aliases.startsWith("X") }

    internal static var aliases: Property<Organization, String, Void> { return Property<Organization, String, Void>(propertyId: 6, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .searchKey.startsWith("X") }

    internal static var searchKey: Property<Organization, String, Void> { return Property<Organization, String, Void>(propertyId: 4, isPrimaryKey: false) }

    /// Use `.files` to refer to this ToMany relation property in queries, like when using
    /// `QueryBuilder.and(property:, conditions:)`.

    internal static var files: ToManyProperty<IndexedFile> { return ToManyProperty(.backlinkRelationId(3)) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `Organization.EntityBindingType`.
internal final class OrganizationBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = Organization
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_name = propertyCollector.prepare(string: entity.name)
        let propertyOffset_nameKey = propertyCollector.prepare(string: entity.nameKey)
        let propertyOffset_kind = propertyCollector.prepare(string: entity.kind)
        let propertyOffset_aliases = propertyCollector.prepare(string: entity.aliases)
        let propertyOffset_searchKey = propertyCollector.prepare(string: entity.searchKey)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(dataOffset: propertyOffset_name, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_nameKey, at: 2 + 2 * 3)
        propertyCollector.collect(dataOffset: propertyOffset_kind, at: 2 + 2 * 5)
        propertyCollector.collect(dataOffset: propertyOffset_aliases, at: 2 + 2 * 6)
        propertyCollector.collect(dataOffset: propertyOffset_searchKey, at: 2 + 2 * 4)
    }

    internal func postPut(fromEntity entity: EntityType, id: ObjectBox.Id, store: ObjectBox.Store) throws {
        if entityId(of: entity) == 0 {  // New object was put? Attach relations now that we have an ID.
            let files = ToMany<IndexedFile>.backlink(
                sourceBox: store.box(for: ToMany<IndexedFile>.ReferencedType.self),
                targetId: EntityId<Organization>(id.value),
                relationId: 3)
            if !entity.files.isEmpty {
                files.replace(entity.files)
            }
            entity.files = files
            try entity.files.applyToDb()
        }
    }
    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = Organization()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.name = entityReader.read(at: 2 + 2 * 2)
        entity.nameKey = entityReader.read(at: 2 + 2 * 3)
        entity.kind = entityReader.read(at: 2 + 2 * 5)
        entity.aliases = entityReader.read(at: 2 + 2 * 6)
        entity.searchKey = entityReader.read(at: 2 + 2 * 4)

        entity.files = ToMany<IndexedFile>.backlink(
            sourceBox: store.box(for: ToMany<IndexedFile>.ReferencedType.self),
            targetId: EntityId<Organization>(entity.id.value),
            relationId: 3)
        return entity
    }
}



extension Person: ObjectBox.__EntityRelatable {
    internal typealias EntityType = Person

    internal var _id: EntityId<Person> {
        return EntityId<Person>(self.id.value)
    }
}

extension Person: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = PersonBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static let entityInfo = ObjectBox.EntityInfo(name: "Person", id: 7)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: Person.self, id: 7, uid: 8143474250481410304)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 6545870208753958912)
        try entityBuilder.addProperty(name: "contactIdentifier", type: PropertyType.string, flags: [.indexed, .indexHash], id: 2, uid: 410353910433238528, indexId: 9, indexUid: 3340932590736234240)
        try entityBuilder.addProperty(name: "name", type: PropertyType.string, id: 3, uid: 9027283165553293824)
        try entityBuilder.addProperty(name: "nameKey", type: PropertyType.string, flags: [.indexed, .indexHash], id: 4, uid: 1088419806363364096, indexId: 10, indexUid: 5557879992484985856)
        try entityBuilder.addProperty(name: "organizationName", type: PropertyType.string, id: 5, uid: 2069914985330662656)
        try entityBuilder.addProperty(name: "jobTitle", type: PropertyType.string, id: 6, uid: 2651107026551955712)
        try entityBuilder.addProperty(name: "emails", type: PropertyType.string, id: 7, uid: 1213383903174705664)
        try entityBuilder.addProperty(name: "phones", type: PropertyType.string, id: 8, uid: 8735027323036753664)
        try entityBuilder.addProperty(name: "source", type: PropertyType.string, id: 10, uid: 3195300607290535424)
        try entityBuilder.addProperty(name: "searchKey", type: PropertyType.string, id: 9, uid: 2752823985249400320)

        try entityBuilder.lastProperty(id: 10, uid: 3195300607290535424)
    }
}

extension Person {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Person.id == myId }
    internal static var id: Property<Person, Id, Id> { return Property<Person, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Person.contactIdentifier.startsWith("X") }
    internal static var contactIdentifier: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Person.name.startsWith("X") }
    internal static var name: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 3, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Person.nameKey.startsWith("X") }
    internal static var nameKey: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 4, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Person.organizationName.startsWith("X") }
    internal static var organizationName: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 5, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Person.jobTitle.startsWith("X") }
    internal static var jobTitle: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 6, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Person.emails.startsWith("X") }
    internal static var emails: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 7, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Person.phones.startsWith("X") }
    internal static var phones: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 8, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Person.source.startsWith("X") }
    internal static var source: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 10, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { Person.searchKey.startsWith("X") }
    internal static var searchKey: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 9, isPrimaryKey: false) }
    /// Use `Person.files` to refer to this ToMany relation property in queries,
    /// like when using `QueryBuilder.and(property:, conditions:)`.

    internal static var files: ToManyProperty<IndexedFile> { return ToManyProperty(.backlinkRelationId(2)) }


    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == Person {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<Person, Id, Id> { return Property<Person, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .contactIdentifier.startsWith("X") }

    internal static var contactIdentifier: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .name.startsWith("X") }

    internal static var name: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 3, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .nameKey.startsWith("X") }

    internal static var nameKey: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 4, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .organizationName.startsWith("X") }

    internal static var organizationName: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 5, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .jobTitle.startsWith("X") }

    internal static var jobTitle: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 6, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .emails.startsWith("X") }

    internal static var emails: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 7, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .phones.startsWith("X") }

    internal static var phones: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 8, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .source.startsWith("X") }

    internal static var source: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 10, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .searchKey.startsWith("X") }

    internal static var searchKey: Property<Person, String, Void> { return Property<Person, String, Void>(propertyId: 9, isPrimaryKey: false) }

    /// Use `.files` to refer to this ToMany relation property in queries, like when using
    /// `QueryBuilder.and(property:, conditions:)`.

    internal static var files: ToManyProperty<IndexedFile> { return ToManyProperty(.backlinkRelationId(2)) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `Person.EntityBindingType`.
internal final class PersonBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = Person
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_contactIdentifier = propertyCollector.prepare(string: entity.contactIdentifier)
        let propertyOffset_name = propertyCollector.prepare(string: entity.name)
        let propertyOffset_nameKey = propertyCollector.prepare(string: entity.nameKey)
        let propertyOffset_organizationName = propertyCollector.prepare(string: entity.organizationName)
        let propertyOffset_jobTitle = propertyCollector.prepare(string: entity.jobTitle)
        let propertyOffset_emails = propertyCollector.prepare(string: entity.emails)
        let propertyOffset_phones = propertyCollector.prepare(string: entity.phones)
        let propertyOffset_source = propertyCollector.prepare(string: entity.source)
        let propertyOffset_searchKey = propertyCollector.prepare(string: entity.searchKey)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(dataOffset: propertyOffset_contactIdentifier, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_name, at: 2 + 2 * 3)
        propertyCollector.collect(dataOffset: propertyOffset_nameKey, at: 2 + 2 * 4)
        propertyCollector.collect(dataOffset: propertyOffset_organizationName, at: 2 + 2 * 5)
        propertyCollector.collect(dataOffset: propertyOffset_jobTitle, at: 2 + 2 * 6)
        propertyCollector.collect(dataOffset: propertyOffset_emails, at: 2 + 2 * 7)
        propertyCollector.collect(dataOffset: propertyOffset_phones, at: 2 + 2 * 8)
        propertyCollector.collect(dataOffset: propertyOffset_source, at: 2 + 2 * 10)
        propertyCollector.collect(dataOffset: propertyOffset_searchKey, at: 2 + 2 * 9)
    }

    internal func postPut(fromEntity entity: EntityType, id: ObjectBox.Id, store: ObjectBox.Store) throws {
        if entityId(of: entity) == 0 {  // New object was put? Attach relations now that we have an ID.
            let files = ToMany<IndexedFile>.backlink(
                sourceBox: store.box(for: ToMany<IndexedFile>.ReferencedType.self),
                targetId: EntityId<Person>(id.value),
                relationId: 2)
            if !entity.files.isEmpty {
                files.replace(entity.files)
            }
            entity.files = files
            try entity.files.applyToDb()
        }
    }
    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = Person()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.contactIdentifier = entityReader.read(at: 2 + 2 * 2)
        entity.name = entityReader.read(at: 2 + 2 * 3)
        entity.nameKey = entityReader.read(at: 2 + 2 * 4)
        entity.organizationName = entityReader.read(at: 2 + 2 * 5)
        entity.jobTitle = entityReader.read(at: 2 + 2 * 6)
        entity.emails = entityReader.read(at: 2 + 2 * 7)
        entity.phones = entityReader.read(at: 2 + 2 * 8)
        entity.source = entityReader.read(at: 2 + 2 * 10)
        entity.searchKey = entityReader.read(at: 2 + 2 * 9)

        entity.files = ToMany<IndexedFile>.backlink(
            sourceBox: store.box(for: ToMany<IndexedFile>.ReferencedType.self),
            targetId: EntityId<Person>(entity.id.value),
            relationId: 2)
        return entity
    }
}



extension ReminderItem: ObjectBox.__EntityRelatable {
    internal typealias EntityType = ReminderItem

    internal var _id: EntityId<ReminderItem> {
        return EntityId<ReminderItem>(self.id.value)
    }
}

extension ReminderItem: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = ReminderItemBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static let entityInfo = ObjectBox.EntityInfo(name: "ReminderItem", id: 8)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: ReminderItem.self, id: 8, uid: 8602322448999801088)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 3001468610839499008)
        try entityBuilder.addProperty(name: "identifier", type: PropertyType.string, flags: [.indexed, .indexHash, .unique], id: 2, uid: 6905147736083682048, indexId: 11, indexUid: 5756466346025054976)
        try entityBuilder.addProperty(name: "title", type: PropertyType.string, id: 3, uid: 7525959344896887552)
        try entityBuilder.addProperty(name: "notes", type: PropertyType.string, id: 4, uid: 2302449541805741824)
        try entityBuilder.addProperty(name: "listName", type: PropertyType.string, id: 5, uid: 450090034738650112)
        try entityBuilder.addProperty(name: "due", type: PropertyType.date, id: 6, uid: 682900125880243712)
        try entityBuilder.addProperty(name: "priority", type: PropertyType.long, id: 7, uid: 4643280151267359744)
        try entityBuilder.addProperty(name: "searchKey", type: PropertyType.string, id: 8, uid: 7861211395970142720)

        try entityBuilder.lastProperty(id: 8, uid: 7861211395970142720)
    }
}

extension ReminderItem {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ReminderItem.id == myId }
    internal static var id: Property<ReminderItem, Id, Id> { return Property<ReminderItem, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ReminderItem.identifier.startsWith("X") }
    internal static var identifier: Property<ReminderItem, String, Void> { return Property<ReminderItem, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ReminderItem.title.startsWith("X") }
    internal static var title: Property<ReminderItem, String, Void> { return Property<ReminderItem, String, Void>(propertyId: 3, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ReminderItem.notes.startsWith("X") }
    internal static var notes: Property<ReminderItem, String, Void> { return Property<ReminderItem, String, Void>(propertyId: 4, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ReminderItem.listName.startsWith("X") }
    internal static var listName: Property<ReminderItem, String, Void> { return Property<ReminderItem, String, Void>(propertyId: 5, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ReminderItem.due > 1234 }
    internal static var due: Property<ReminderItem, Date?, Void> { return Property<ReminderItem, Date?, Void>(propertyId: 6, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ReminderItem.priority > 1234 }
    internal static var priority: Property<ReminderItem, Int, Void> { return Property<ReminderItem, Int, Void>(propertyId: 7, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ReminderItem.searchKey.startsWith("X") }
    internal static var searchKey: Property<ReminderItem, String, Void> { return Property<ReminderItem, String, Void>(propertyId: 8, isPrimaryKey: false) }

    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == ReminderItem {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<ReminderItem, Id, Id> { return Property<ReminderItem, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .identifier.startsWith("X") }

    internal static var identifier: Property<ReminderItem, String, Void> { return Property<ReminderItem, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .title.startsWith("X") }

    internal static var title: Property<ReminderItem, String, Void> { return Property<ReminderItem, String, Void>(propertyId: 3, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .notes.startsWith("X") }

    internal static var notes: Property<ReminderItem, String, Void> { return Property<ReminderItem, String, Void>(propertyId: 4, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .listName.startsWith("X") }

    internal static var listName: Property<ReminderItem, String, Void> { return Property<ReminderItem, String, Void>(propertyId: 5, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .due > 1234 }

    internal static var due: Property<ReminderItem, Date?, Void> { return Property<ReminderItem, Date?, Void>(propertyId: 6, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .priority > 1234 }

    internal static var priority: Property<ReminderItem, Int, Void> { return Property<ReminderItem, Int, Void>(propertyId: 7, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .searchKey.startsWith("X") }

    internal static var searchKey: Property<ReminderItem, String, Void> { return Property<ReminderItem, String, Void>(propertyId: 8, isPrimaryKey: false) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `ReminderItem.EntityBindingType`.
internal final class ReminderItemBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = ReminderItem
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_identifier = propertyCollector.prepare(string: entity.identifier)
        let propertyOffset_title = propertyCollector.prepare(string: entity.title)
        let propertyOffset_notes = propertyCollector.prepare(string: entity.notes)
        let propertyOffset_listName = propertyCollector.prepare(string: entity.listName)
        let propertyOffset_searchKey = propertyCollector.prepare(string: entity.searchKey)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(entity.due, at: 2 + 2 * 6)
        propertyCollector.collect(entity.priority, at: 2 + 2 * 7)
        propertyCollector.collect(dataOffset: propertyOffset_identifier, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_title, at: 2 + 2 * 3)
        propertyCollector.collect(dataOffset: propertyOffset_notes, at: 2 + 2 * 4)
        propertyCollector.collect(dataOffset: propertyOffset_listName, at: 2 + 2 * 5)
        propertyCollector.collect(dataOffset: propertyOffset_searchKey, at: 2 + 2 * 8)
    }

    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = ReminderItem()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.identifier = entityReader.read(at: 2 + 2 * 2)
        entity.title = entityReader.read(at: 2 + 2 * 3)
        entity.notes = entityReader.read(at: 2 + 2 * 4)
        entity.listName = entityReader.read(at: 2 + 2 * 5)
        entity.due = entityReader.read(at: 2 + 2 * 6)
        entity.priority = entityReader.read(at: 2 + 2 * 7)
        entity.searchKey = entityReader.read(at: 2 + 2 * 8)

        return entity
    }
}



extension ScreenshotItem: ObjectBox.__EntityRelatable {
    internal typealias EntityType = ScreenshotItem

    internal var _id: EntityId<ScreenshotItem> {
        return EntityId<ScreenshotItem>(self.id.value)
    }
}

extension ScreenshotItem: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = ScreenshotItemBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static let entityInfo = ObjectBox.EntityInfo(name: "ScreenshotItem", id: 3)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: ScreenshotItem.self, id: 3, uid: 4765101354586054400)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 512565397925974784)
        try entityBuilder.addProperty(name: "path", type: PropertyType.string, flags: [.indexed, .indexHash, .unique], id: 2, uid: 8020519287356986880, indexId: 3, indexUid: 1742743780222572032)
        try entityBuilder.addProperty(name: "createdAt", type: PropertyType.date, id: 3, uid: 8417958069847682560)
        try entityBuilder.addProperty(name: "modifiedAt", type: PropertyType.date, id: 4, uid: 6587186256472179712)
        try entityBuilder.addProperty(name: "text", type: PropertyType.string, id: 5, uid: 7874742908709286400)
        try entityBuilder.addProperty(name: "searchKey", type: PropertyType.string, id: 6, uid: 4829703565059312384)

        try entityBuilder.lastProperty(id: 6, uid: 4829703565059312384)
    }
}

extension ScreenshotItem {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ScreenshotItem.id == myId }
    internal static var id: Property<ScreenshotItem, Id, Id> { return Property<ScreenshotItem, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ScreenshotItem.path.startsWith("X") }
    internal static var path: Property<ScreenshotItem, String, Void> { return Property<ScreenshotItem, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ScreenshotItem.createdAt > 1234 }
    internal static var createdAt: Property<ScreenshotItem, Date, Void> { return Property<ScreenshotItem, Date, Void>(propertyId: 3, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ScreenshotItem.modifiedAt > 1234 }
    internal static var modifiedAt: Property<ScreenshotItem, Date, Void> { return Property<ScreenshotItem, Date, Void>(propertyId: 4, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ScreenshotItem.text.startsWith("X") }
    internal static var text: Property<ScreenshotItem, String, Void> { return Property<ScreenshotItem, String, Void>(propertyId: 5, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ScreenshotItem.searchKey.startsWith("X") }
    internal static var searchKey: Property<ScreenshotItem, String, Void> { return Property<ScreenshotItem, String, Void>(propertyId: 6, isPrimaryKey: false) }

    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == ScreenshotItem {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<ScreenshotItem, Id, Id> { return Property<ScreenshotItem, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .path.startsWith("X") }

    internal static var path: Property<ScreenshotItem, String, Void> { return Property<ScreenshotItem, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .createdAt > 1234 }

    internal static var createdAt: Property<ScreenshotItem, Date, Void> { return Property<ScreenshotItem, Date, Void>(propertyId: 3, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .modifiedAt > 1234 }

    internal static var modifiedAt: Property<ScreenshotItem, Date, Void> { return Property<ScreenshotItem, Date, Void>(propertyId: 4, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .text.startsWith("X") }

    internal static var text: Property<ScreenshotItem, String, Void> { return Property<ScreenshotItem, String, Void>(propertyId: 5, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .searchKey.startsWith("X") }

    internal static var searchKey: Property<ScreenshotItem, String, Void> { return Property<ScreenshotItem, String, Void>(propertyId: 6, isPrimaryKey: false) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `ScreenshotItem.EntityBindingType`.
internal final class ScreenshotItemBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = ScreenshotItem
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_path = propertyCollector.prepare(string: entity.path)
        let propertyOffset_text = propertyCollector.prepare(string: entity.text)
        let propertyOffset_searchKey = propertyCollector.prepare(string: entity.searchKey)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(entity.createdAt, at: 2 + 2 * 3)
        propertyCollector.collect(entity.modifiedAt, at: 2 + 2 * 4)
        propertyCollector.collect(dataOffset: propertyOffset_path, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_text, at: 2 + 2 * 5)
        propertyCollector.collect(dataOffset: propertyOffset_searchKey, at: 2 + 2 * 6)
    }

    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = ScreenshotItem()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.path = entityReader.read(at: 2 + 2 * 2)
        entity.createdAt = entityReader.read(at: 2 + 2 * 3)
        entity.modifiedAt = entityReader.read(at: 2 + 2 * 4)
        entity.text = entityReader.read(at: 2 + 2 * 5)
        entity.searchKey = entityReader.read(at: 2 + 2 * 6)

        return entity
    }
}


/// Helper function that allows calling Enum(rawValue: value) with a nil value, which will return nil.
fileprivate func optConstruct<T: RawRepresentable>(_ type: T.Type, rawValue: T.RawValue?) -> T? {
    guard let rawValue = rawValue else { return nil }
    return T(rawValue: rawValue)
}

// MARK: - Store setup

fileprivate func cModel() throws -> OpaquePointer {
    let modelBuilder = try ObjectBox.ModelBuilder()
    try CalendarEvent.buildEntity(modelBuilder: modelBuilder)
    try ClaudeSession.buildEntity(modelBuilder: modelBuilder)
    try ClipboardItem.buildEntity(modelBuilder: modelBuilder)
    try IndexedFile.buildEntity(modelBuilder: modelBuilder)
    try Organization.buildEntity(modelBuilder: modelBuilder)
    try Person.buildEntity(modelBuilder: modelBuilder)
    try ReminderItem.buildEntity(modelBuilder: modelBuilder)
    try ScreenshotItem.buildEntity(modelBuilder: modelBuilder)
    modelBuilder.lastEntity(id: 8, uid: 8602322448999801088)
    modelBuilder.lastIndex(id: 11, uid: 5756466346025054976)
    modelBuilder.lastRelation(id: 3, uid: 8094558302600375296)
    return modelBuilder.finish()
}

extension ObjectBox.Store {
    /// A store with a fully configured model. Created by the code generator with your model's metadata in place.
    ///
    /// # In-memory database
    /// To use a file-less in-memory database, instead of a directory path pass `memory:` 
    /// together with an identifier string:
    /// ```swift
    /// let inMemoryStore = try Store(directoryPath: "memory:test-db")
    /// ```
    ///
    /// - Parameters:
    ///   - directoryPath: The directory path in which ObjectBox places its database files for this store,
    ///     or to use an in-memory database `memory:<identifier>`.
    ///   - maxDbSizeInKByte: Limit of on-disk space for the database files. Default is `1024 * 1024` (1 GiB).
    ///   - fileMode: UNIX-style bit mask used for the database files; default is `0o644`.
    ///     Note: directories become searchable if the "read" or "write" permission is set (e.g. 0640 becomes 0750).
    ///   - maxReaders: The maximum number of readers.
    ///     "Readers" are a finite resource for which we need to define a maximum number upfront.
    ///     The default value is enough for most apps and usually you can ignore it completely.
    ///     However, if you get the maxReadersExceeded error, you should verify your
    ///     threading. For each thread, ObjectBox uses multiple readers. Their number (per thread) depends
    ///     on number of types, relations, and usage patterns. Thus, if you are working with many threads
    ///     (e.g. in a server-like scenario), it can make sense to increase the maximum number of readers.
    ///     Note: The internal default is currently around 120. So when hitting this limit, try values around 200-500.
    ///   - readOnly: Opens the database in read-only mode, i.e. not allowing write transactions.
    ///
    /// - important: This initializer is created by the code generator. If you only see the internal `init(model:...)`
    ///              initializer, trigger code generation by building your project.
    internal convenience init(directoryPath: String, maxDbSizeInKByte: UInt64 = 1024 * 1024,
                            fileMode: UInt32 = 0o644, maxReaders: UInt32 = 0, readOnly: Bool = false) throws {
        try self.init(
            model: try cModel(),
            directory: directoryPath,
            maxDbSizeInKByte: maxDbSizeInKByte,
            fileMode: fileMode,
            maxReaders: maxReaders,
            readOnly: readOnly)
    }
}

// swiftlint:enable all
