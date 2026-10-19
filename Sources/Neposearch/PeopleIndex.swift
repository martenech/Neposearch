import Contacts
import EventKit
import Foundation
import ObjectBox
import Observation

/// Osoby, firmy, udalosti a pripomienky z Kontaktov, Kalendára a Pripomienok – a ich prepojenia so súbormi.
@MainActor @Observable
final class PeopleIndex {
    private(set) var personCount = 0
    private(set) var organizationCount = 0
    private(set) var eventCount = 0
    private(set) var reminderCount = 0
    private(set) var linkedFileCount = UserDefaults.standard.integer(forKey: "peopleLinkedFileCount")
    private(set) var contactsProblem: String?
    private(set) var calendarProblem: String?
    /// Priebeh triedenia názvov zo súborov (hotové, spolu).
    private(set) var extractionProgress: (done: Int, total: Int)?
    private(set) var extractionProblem: String?
    /// Mení sa pri každom importe (aby sa obnovili zoznamy).
    private(set) var revision = 0

    @ObservationIgnored let persons: Box<Person>
    @ObservationIgnored let organizations: Box<Organization>
    @ObservationIgnored let events: Box<CalendarEvent>
    @ObservationIgnored let reminders: Box<ReminderItem>
    @ObservationIgnored private let files: Box<IndexedFile>
    @ObservationIgnored private let database: Database
    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let eventStore = EKEventStore()
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var linkTimer: Timer?

    init(database: Database, settings: AppSettings) {
        persons = database.store.box(for: Person.self)
        organizations = database.store.box(for: Organization.self)
        events = database.store.box(for: CalendarEvent.self)
        reminders = database.store.box(for: ReminderItem.self)
        files = database.files
        self.database = database
        self.settings = settings
        updateCounts()
        start()
    }

    func start() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        linkTimer?.invalidate()
        let center = NotificationCenter.default
        if settings.contactsEnabled {
            observers.append(center.addObserver(forName: .CNContactStoreDidChange, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.scheduleRefresh() }
            })
        }
        if settings.calendarEnabled {
            observers.append(center.addObserver(forName: .EKEventStoreChanged, object: eventStore, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.scheduleRefresh() }
            })
        }
        // Nové zhrnuté súbory prepojíme s osobami a firmami každých 10 minút.
        linkTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleRefresh(contactsAndCalendar: false) }
        }
        scheduleRefresh(delay: 0)
    }

    private func scheduleRefresh(delay: Double = 3, contactsAndCalendar: Bool = true) {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            if contactsAndCalendar {
                if settings.contactsEnabled { await importContacts() }
                if settings.calendarEnabled {
                    await importEvents()
                    await importReminders()
                }
            }
            if settings.entitiesEnabled { await extractEntities() }
            await linkFiles()
            updateCounts()
            revision += 1
        }
    }

    private func updateCounts() {
        personCount = (try? persons.count()) ?? 0
        organizationCount = (try? organizations.count()) ?? 0
        eventCount = (try? events.count()) ?? 0
        reminderCount = (try? reminders.count()) ?? 0
    }

    // MARK: - Kontakty

    private struct ContactRecord: Sendable {
        let identifier: String
        let name: String
        let organization: String
        let jobTitle: String
        let emails: [String]
        let phones: [String]
    }

    private func importContacts() async {
        let store = CNContactStore()
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            _ = try? await store.requestAccess(for: .contacts)
        }
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
            contactsProblem = "Povoľ prístup ku Kontaktom (Nastavenia → Súkromie → Kontakty)."
            return
        }
        contactsProblem = nil
        let records = await Task.detached(priority: .utility) { Self.fetchContacts() }.value

        let existing = Dictionary(((try? persons.query { Person.contactIdentifier.isNotEqual(to: "") }.build().find()) ?? [])
            .map { ($0.contactIdentifier, $0) }, uniquingKeysWith: { a, _ in a })
        var updated: [Person] = []
        var seen = Set<String>()
        var organizationNames = Set<String>()
        for record in records {
            seen.insert(record.identifier)
            let person = existing[record.identifier] ?? Person()
            person.contactIdentifier = record.identifier
            person.name = record.name
            person.nameKey = IndexedFile.normalize(record.name)
            person.organizationName = record.organization
            person.jobTitle = record.jobTitle
            person.emails = record.emails.map { $0.lowercased() }.joined(separator: ", ")
            person.phones = record.phones.joined(separator: ", ")
            person.searchKey = IndexedFile.normalize("\(record.name) \(record.organization) \(record.jobTitle) \(person.emails)")
            updated.append(person)
            if !record.organization.isEmpty { organizationNames.insert(record.organization) }
        }
        _ = try? persons.put(updated)
        let removed = existing.values.filter { !seen.contains($0.contactIdentifier) }
        if !removed.isEmpty { _ = try? persons.remove(removed.map(\.id)) }
        upsertOrganizations(organizationNames)
    }

    nonisolated private static func fetchContacts() -> [ContactRecord] {
        let keys: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactOrganizationNameKey as CNKeyDescriptor, CNContactJobTitleKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor,
        ]
        var result: [ContactRecord] = []
        try? CNContactStore().enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys)) { contact, _ in
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
            guard !name.isEmpty || !contact.organizationName.isEmpty else { return }
            result.append(ContactRecord(
                identifier: contact.identifier,
                name: name.isEmpty ? contact.organizationName : name,
                organization: contact.organizationName,
                jobTitle: contact.jobTitle,
                emails: contact.emailAddresses.map { $0.value as String },
                phones: contact.phoneNumbers.map { $0.value.stringValue }))
        }
        return result
    }

    private func upsertOrganizations(_ names: Set<String>) {
        let existing = Set(((try? organizations.all()) ?? []).map(\.nameKey))
        let new = names.filter { !existing.contains(IndexedFile.normalize($0)) }.map { name -> Organization in
            let organization = Organization()
            organization.name = name
            organization.nameKey = IndexedFile.normalize(name)
            organization.searchKey = organization.nameKey
            return organization
        }
        if !new.isEmpty { _ = try? organizations.put(new) }
    }

    // MARK: - Kalendár

    private struct EventRecord: Sendable {
        let key: String
        let identifier: String
        let title: String
        let start: Date
        let end: Date
        let isAllDay: Bool
        let location: String
        let notes: String
        let calendar: String
        let attendees: [(name: String, email: String)]
        let meetingURL: String
    }

    private func importEvents() async {
        if EKEventStore.authorizationStatus(for: .event) == .notDetermined {
            _ = try? await eventStore.requestFullAccessToEvents()
        }
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            calendarProblem = "Povoľ prístup ku Kalendáru (Nastavenia → Súkromie → Kalendáre)."
            return
        }
        calendarProblem = nil
        let start = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        let end = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let records = eventStore.events(matching: predicate).compactMap(Self.record(from:))

        let existing = Dictionary(((try? events.all()) ?? []).map { ($0.key, $0) }, uniquingKeysWith: { a, _ in a })
        // Osoby podľa e-mailu, aby sme účastníkov prepojili s kontaktmi.
        var byEmail: [String: Person] = [:]
        for person in (try? persons.all()) ?? [] {
            for email in person.emails.split(separator: ",") { byEmail[email.trimmingCharacters(in: .whitespaces)] = person }
        }
        var updated: [CalendarEvent] = []
        var newPeople: [Person] = []
        for record in records {
            let event = existing[record.key] ?? CalendarEvent()
            event.key = record.key
            event.eventIdentifier = record.identifier
            event.title = record.title
            event.start = record.start
            event.end = record.end
            event.isAllDay = record.isAllDay
            event.location = record.location
            event.notes = record.notes
            event.calendarName = record.calendar
            event.meetingURL = record.meetingURL
            event.attendeesText = record.attendees.map { $0.name.isEmpty ? $0.email : "\($0.name) <\($0.email)>" }.joined(separator: ", ")
            event.searchKey = IndexedFile.normalize("\(record.title) \(record.location) \(event.attendeesText) \(record.notes.prefix(300))")
            var attendees: [Person] = []
            for attendee in record.attendees where !attendee.email.isEmpty {
                if let person = byEmail[attendee.email] {
                    attendees.append(person)
                } else if !attendee.name.isEmpty {
                    // Účastník, ktorý nie je v Kontaktoch – osoba len z kalendára.
                    let person = Person()
                    person.name = attendee.name
                    person.nameKey = IndexedFile.normalize(attendee.name)
                    person.emails = attendee.email
                    person.searchKey = IndexedFile.normalize("\(attendee.name) \(attendee.email)")
                    byEmail[attendee.email] = person
                    newPeople.append(person)
                    attendees.append(person)
                }
            }
            if !newPeople.isEmpty { _ = try? persons.put(newPeople); newPeople = [] }
            event.attendees.replace(attendees)
            updated.append(event)
        }
        _ = try? events.put(updated)
        for event in updated { try? event.attendees.applyToDb() }
        let keys = Set(records.map(\.key))
        let removed = existing.values.filter { !keys.contains($0.key) }
        if !removed.isEmpty { _ = try? events.remove(removed.map(\.id)) }
    }

    nonisolated private static func record(from event: EKEvent) -> EventRecord? {
        guard let identifier = event.eventIdentifier, let start = event.startDate, let end = event.endDate else { return nil }
        let attendees = (event.attendees ?? []).filter { !$0.isCurrentUser }.map { participant -> (String, String) in
            let email = participant.url.absoluteString.replacingOccurrences(of: "mailto:", with: "").lowercased()
            return (participant.name ?? "", email.contains("@") ? email : "")
        }
        let text = "\(event.location ?? "") \(event.notes ?? "") \(event.url?.absoluteString ?? "")"
        let meeting = text.range(of: #"https://[^\s<>"]*(meet\.google\.com|zoom\.us|teams\.microsoft\.com|webex\.com)[^\s<>"]*"#, options: .regularExpression)
            .map { String(text[$0]) } ?? event.url?.absoluteString ?? ""
        return EventRecord(
            key: "\(identifier)|\(Int(start.timeIntervalSince1970))", identifier: identifier, title: event.title ?? "",
            start: start, end: end, isAllDay: event.isAllDay, location: event.location ?? "",
            notes: String((event.notes ?? "").prefix(1000)), calendar: event.calendar?.title ?? "",
            attendees: attendees, meetingURL: meeting)
    }

    // MARK: - Pripomienky

    private struct ReminderRecord: Sendable {
        let identifier: String
        let title: String
        let notes: String
        let list: String
        let due: Date?
        let priority: Int
    }

    private func importReminders() async {
        if EKEventStore.authorizationStatus(for: .reminder) == .notDetermined {
            _ = try? await eventStore.requestFullAccessToReminders()
        }
        guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else { return }
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        let records: [ReminderRecord] = await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: (reminders ?? []).map { reminder in
                    ReminderRecord(
                        identifier: reminder.calendarItemIdentifier, title: reminder.title ?? "", notes: reminder.notes ?? "",
                        list: reminder.calendar?.title ?? "", due: reminder.dueDateComponents?.date, priority: reminder.priority)
                })
            }
        }
        let existing = Dictionary(((try? reminders.all()) ?? []).map { ($0.identifier, $0) }, uniquingKeysWith: { a, _ in a })
        let updated = records.map { record -> ReminderItem in
            let item = existing[record.identifier] ?? ReminderItem()
            item.identifier = record.identifier
            item.title = record.title
            item.notes = record.notes
            item.listName = record.list
            item.due = record.due
            item.priority = record.priority
            item.searchKey = IndexedFile.normalize("\(record.title) \(record.notes) \(record.list)")
            return item
        }
        _ = try? reminders.put(updated)
        let ids = Set(records.map(\.identifier))
        let removed = existing.values.filter { !ids.contains($0.identifier) }
        if !removed.isEmpty { _ = try? reminders.remove(removed.map(\.id)) }
    }

    /// Označí pripomienku ako hotovú (zapíše do Pripomienok).
    func complete(_ item: ReminderItem) {
        if let reminder = eventStore.calendarItem(withIdentifier: item.identifier) as? EKReminder {
            reminder.isCompleted = true
            try? eventStore.save(reminder, commit: true)
        }
        _ = try? reminders.remove(item.id)
        updateCounts()
        revision += 1
    }

    // MARK: - Prepojenia so súbormi

    /// Súbor, v ktorého zhrnutí sa spomína celé meno osoby (aspoň dve slová) alebo názov firmy, sa s nimi prepojí.
    /// Podpis stavu (počty súborov a entít, posledné zhrnutie) – keď sa nezmení, prepájať netreba.
    /// Pamätá sa aj medzi spusteniami, inak by sa po každom štarte prepájalo všetko odznova.
    @ObservationIgnored private var lastLinkSignature = UserDefaults.standard.string(forKey: "peopleLinkSignature") ?? ""

    private func linkFiles() async {
        let lastSummary = (try? files.query { IndexedFile.status == IndexStatus.done.rawValue }
            .ordered(by: IndexedFile.indexedAt, flags: .descending).build().findFirst())?.indexedAt ?? .distantPast
        let signature = "\((try? files.count()) ?? 0)|\(lastSummary.timeIntervalSince1970)|\((try? persons.count()) ?? 0)|"
            + "\((try? organizations.count()) ?? 0)|\(EntityExtractor.loadCache().count)"
        guard signature != lastLinkSignature else { return }
        let database = database
        guard let linked = await Task.detached(priority: .utility, operation: { Self.link(database: database) }).value
        else { return }
        linkedFileCount = linked
        lastLinkSignature = signature
        UserDefaults.standard.set(signature, forKey: "peopleLinkSignature")
        UserDefaults.standard.set(linked, forKey: "peopleLinkedFileCount")
    }

    /// Samotné prepájanie beží mimo hlavného vlákna (tisíce súborov × stovky entít). Vráti počet prepojených súborov.
    nonisolated private static func link(database: Database) -> Int? {
        let files = database.files
        let persons = database.store.box(for: Person.self)
        let organizations = database.store.box(for: Organization.self)
        let allPeople = (try? persons.all()) ?? []
        let allCompanies = (try? organizations.all()) ?? []
        guard !allPeople.isEmpty || !allCompanies.isEmpty else { return nil }
        let people = allPeople.filter { $0.nameKey.split(separator: " ").count >= 2 && $0.nameKey.count >= 6 }
            .map { ($0, $0.nameKey) }
        let companies = allCompanies.map { ($0, Self.matchKey($0.nameKey)) }.filter { $0.1.count >= 4 }
        // Kľúčové slovo (bez diakritiky) → entita podľa roztriedenia od Claude.
        let personByKey = Dictionary(allPeople.map { ($0.nameKey, $0) }, uniquingKeysWith: { a, b in a.source == "contacts" ? a : b })
        let companyByKey = Dictionary(allCompanies.map { ($0.nameKey, $0) }, uniquingKeysWith: { a, _ in a })
        var personForKeyword: [String: Person] = [:], companyForKeyword: [String: Organization] = [:]
        // Zoradené, aby pri viacerých variantoch toho istého slova („Acme“, „ACME“) vyhral vždy ten istý.
        for (keyword, classified) in EntityExtractor.loadCache().sorted(by: { $0.key < $1.key }) {
            let key = IndexedFile.normalize(keyword), canonical = IndexedFile.normalize(classified.canonical)
            switch classified.type {
            case "person": personForKeyword[key] = personByKey[canonical]
            case "organization", "project": companyForKeyword[key] = companyByKey[canonical]
            default: break
            }
        }
        let personMatcher = PhraseMatcher(people), companyMatcher = PhraseMatcher(companies)
        let all = (try? files.query { IndexedFile.status == IndexStatus.done.rawValue }.build().find()) ?? []
        var changed: [IndexedFile] = []
        var linked = 0
        for file in all {
            let text = file.searchKey
            let words = Set(text.split { !$0.isLetter })
            let tokens = (file.keywords + "," + file.tags).split(separator: ",").map { IndexedFile.normalize($0.trimmingCharacters(in: .whitespaces)) }
            var matchedPeople = personMatcher.matches(in: text, words: words)
            var matchedCompanies = companyMatcher.matches(in: text, words: words)
            for token in tokens {
                if let person = personForKeyword[token], !matchedPeople.contains(where: { $0.id == person.id }) { matchedPeople.append(person) }
                if let company = companyForKeyword[token], !matchedCompanies.contains(where: { $0.id == company.id }) {
                    matchedCompanies.append(company)
                }
            }
            if !matchedPeople.isEmpty || !matchedCompanies.isEmpty { linked += 1 }
            let currentPeople = Set(file.people.map(\.id.value)), currentCompanies = Set(file.organizations.map(\.id.value))
            guard currentPeople != Set(matchedPeople.map(\.id.value)) || currentCompanies != Set(matchedCompanies.map(\.id.value))
            else { continue }
            file.people.replace(matchedPeople)
            file.organizations.replace(matchedCompanies)
            changed.append(file)
        }
        // Vzťahy ToMany sa zapisujú samostatne (put uloží len samotný objekt).
        for file in changed {
            try? file.people.applyToDb()
            try? file.organizations.applyToDb()
        }
        return linked
    }

    /// Hľadá frázy (mená, názvy firiem) ako celé slová. Fráza sa môže zhodovať len vtedy, keď sú všetky jej slová
    /// aj medzi slovami textu – kandidátov preto vyberie podľa prvého slova a presne (`containsWord`) overí len tie.
    private struct PhraseMatcher<Entity> {
        private var byFirstWord: [Substring: [(entity: Entity, phrase: String, words: [Substring])]] = [:]
        /// Frázy bez písmen (napr. len čísla) sa nedajú zaradiť podľa slova, overujú sa vždy.
        private var others: [(entity: Entity, phrase: String)] = []

        init(_ entries: [(Entity, String)]) {
            for (entity, phrase) in entries {
                let words = phrase.split { !$0.isLetter }
                if let first = words.first {
                    byFirstWord[first, default: []].append((entity, phrase, words))
                } else {
                    others.append((entity, phrase))
                }
            }
        }

        func matches(in text: String, words: Set<Substring>) -> [Entity] {
            var result: [Entity] = []
            for word in words {
                for candidate in byFirstWord[word] ?? []
                where candidate.words.allSatisfy(words.contains) && PeopleIndex.containsWord(text, candidate.phrase) {
                    result.append(candidate.entity)
                }
            }
            for other in others where PeopleIndex.containsWord(text, other.phrase) { result.append(other.entity) }
            return result
        }
    }

    // MARK: - Osoby, firmy a projekty zo súborov

    /// Nové vlastné mená z kľúčových slov roztriedi Claude (po dávkach) a vytvorí z nich entity.
    private func extractEntities() async {
        var cache = EntityExtractor.loadCache()
        let done = (try? files.query { IndexedFile.status == IndexStatus.done.rawValue }.build().find()) ?? []
        let pending = EntityExtractor.candidates(in: done).subtracting(cache.keys).sorted()
        if !pending.isEmpty {
            guard case .success(let model) = settings.makeModel() else {
                extractionProblem = "AI nie je nastavená – osoby a firmy zo súborov sa nedajú roztriediť."
                return
            }
            extractionProblem = nil
            let extractor = EntityExtractor(model: model)
            var processed = 0
            extractionProgress = (0, pending.count)
            for start in stride(from: 0, to: pending.count, by: 250) {
                let batch = Array(pending[start..<min(start + 250, pending.count)])
                do {
                    let result = try await extractor.classify(batch)
                    // Čo model vynechal, označíme ako „other“, aby sme sa nepýtali stále dookola.
                    for keyword in batch { cache[keyword] = result[keyword] ?? .init(type: "other", canonical: keyword) }
                    EntityExtractor.saveCache(cache)
                } catch {
                    extractionProblem = "Triedenie názvov zlyhalo: \(error.localizedDescription)"
                    break
                }
                processed += batch.count
                extractionProgress = (processed, pending.count)
            }
            extractionProgress = nil
        }
        createEntities(from: cache)
    }

    /// Z roztriedených názvov vytvorí osoby a firmy/projekty (osoby z Kontaktov sa nezdvojujú).
    private func createEntities(from cache: [String: EntityExtractor.Classified]) {
        var groups: [String: (type: String, name: String, variants: Set<String>)] = [:]
        for (keyword, classified) in cache where ["person", "organization", "project"].contains(classified.type) {
            let key = IndexedFile.normalize(classified.canonical)
            var group = groups[key] ?? (classified.type, classified.canonical, [])
            group.variants.insert(keyword)
            groups[key] = group
        }
        let existingPeople = Set(((try? persons.all()) ?? []).map(\.nameKey))
        let existingCompanies = Dictionary(((try? organizations.all()) ?? []).map { ($0.nameKey, $0) }, uniquingKeysWith: { a, _ in a })
        var newPeople: [Person] = [], updatedCompanies: [Organization] = []
        for (key, group) in groups {
            if group.type == "person" {
                guard !existingPeople.contains(key) else { continue }
                let person = Person()
                person.name = group.name
                person.nameKey = key
                person.source = "ai"
                person.searchKey = IndexedFile.normalize("\(group.name) \(group.variants.joined(separator: " "))")
                newPeople.append(person)
            } else {
                let company = existingCompanies[key] ?? Organization()
                company.name = group.name
                company.nameKey = key
                company.kind = group.type
                company.aliases = group.variants.sorted().joined(separator: ", ")
                company.searchKey = IndexedFile.normalize("\(group.name) \(company.aliases)")
                updatedCompanies.append(company)
            }
        }
        if !newPeople.isEmpty { _ = try? persons.put(newPeople) }
        if !updatedCompanies.isEmpty { _ = try? organizations.put(updatedCompanies) }
    }

    /// Názov firmy bez právnej formy („Acme s.r.o.“ → „acme“).
    nonisolated static func matchKey(_ nameKey: String) -> String {
        var key = nameKey
        for suffix in [" s.r.o.", " s. r. o.", " s.r.o", " a.s.", " spol.", " inc.", " inc", " ltd.", " ltd", " gmbh", " llc", ","] {
            key = key.replacingOccurrences(of: suffix, with: "")
        }
        return key.trimmingCharacters(in: .whitespaces)
    }

    /// Obsahuje text frázu ako celé slová (nie „jan“ v „januar“)?
    nonisolated static func containsWord(_ text: String, _ phrase: String) -> Bool {
        guard !phrase.isEmpty else { return false }
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: phrase, range: searchRange) {
            let before = range.lowerBound == text.startIndex ? nil : text[text.index(before: range.lowerBound)]
            let after = range.upperBound == text.endIndex ? nil : text[range.upperBound]
            if !(before?.isLetter ?? false), !(after?.isLetter ?? false) { return true }
            searchRange = range.upperBound..<text.endIndex
        }
        return false
    }

    // MARK: - Hľadanie

    func searchPeople(_ query: String, limit: Int) -> [Person] {
        _ = revision
        return search(persons, key: Person.searchKey, query: query, limit: limit)
    }

    func searchOrganizations(_ query: String, limit: Int) -> [Organization] {
        _ = revision
        return search(organizations, key: Organization.searchKey, query: query, limit: limit)
    }

    /// Udalosti: najbližšie budúce prvé, potom nedávne.
    func searchEvents(_ query: String, limit: Int) -> [CalendarEvent] {
        _ = revision
        let found = search(events, key: CalendarEvent.searchKey, query: query, limit: 200)
        let now = Date()
        let upcoming = found.filter { $0.end >= now }.sorted { $0.start < $1.start }
        let past = found.filter { $0.end < now }.sorted { $0.start > $1.start }
        return Array((upcoming + past).prefix(limit))
    }

    func upcomingEvents(days: Int, limit: Int) -> [CalendarEvent] {
        _ = revision
        let now = Date(), until = Calendar.current.date(byAdding: .day, value: days, to: now)!
        return ((try? events.all()) ?? []).filter { $0.end >= now && $0.start <= until }
            .sorted { $0.start < $1.start }.prefix(limit).map { $0 }
    }

    func searchReminders(_ query: String, limit: Int) -> [ReminderItem] {
        _ = revision
        return search(reminders, key: ReminderItem.searchKey, query: query, limit: limit)
            .sorted { ($0.due ?? .distantFuture) < ($1.due ?? .distantFuture) }
    }

    private func search<E>(_ box: Box<E>, key: Property<E, String, Void>, query: String, limit: Int) -> [E] {
        let terms = IndexedFile.searchTerms(query)
        guard let first = terms.first else { return (try? box.query().build().find(offset: 0, limit: limit)) ?? [] }
        return (try? box.query {
            terms.dropFirst().reduce(key.contains(first) as QueryCondition<E>) { $0 && key.contains($1) }
        }.build().find(offset: 0, limit: limit)) ?? []
    }

    /// Udalosti, na ktorých je osoba účastníkom.
    func events(with person: Person) -> [CalendarEvent] {
        ((try? events.all()) ?? []).filter { event in event.attendees.contains { $0.id == person.id } }
            .sorted { $0.start > $1.start }
    }
}
