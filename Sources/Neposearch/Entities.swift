import Foundation
import ObjectBox

/// Osoba (z Kontaktov alebo nájdená v súboroch).
// objectbox: entity
class Person {
    var id: Id = 0
    /// CNContact.identifier; prázdne pri osobách, ktoré nie sú v Kontaktoch.
    // objectbox: index
    var contactIdentifier: String = ""
    var name: String = ""
    /// Meno malými písmenami bez diakritiky (na párovanie a hľadanie).
    // objectbox: index
    var nameKey: String = ""
    var organizationName: String = ""
    var jobTitle: String = ""
    /// E-maily oddelené čiarkou (malými písmenami).
    var emails: String = ""
    var phones: String = ""
    /// Odkiaľ osoba pochádza: „contacts“, „calendar“ alebo „ai“ (nájdená v súboroch).
    var source: String = "contacts"
    var searchKey: String = ""
    /// Súbory, v ktorých sa osoba spomína (spätná väzba k IndexedFile.people).
    // objectbox: backlink = "people"
    var files: ToMany<IndexedFile> = nil

    required init() {}
}

extension Person {
    var firstEmail: String? {
        emails.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Iniciály na avatar („Jana Nováková“ → „JN“).
    var initials: String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }
}

/// Firma alebo organizácia.
// objectbox: entity
class Organization {
    var id: Id = 0
    var name: String = ""
    // objectbox: index
    var nameKey: String = ""
    /// „organization“ (firma, inštitúcia, značka) alebo „project“.
    var kind: String = "organization"
    /// Varianty názvu z kľúčových slov (oddelené čiarkou), podľa ktorých sa párujú súbory.
    var aliases: String = ""
    var searchKey: String = ""
    // objectbox: backlink = "organizations"
    var files: ToMany<IndexedFile> = nil

    required init() {}
}

/// Udalosť z Kalendára.
// objectbox: entity
class CalendarEvent {
    var id: Id = 0
    /// eventIdentifier + začiatok (opakované udalosti majú rovnaký identifikátor).
    // objectbox: unique
    var key: String = ""
    var eventIdentifier: String = ""
    var title: String = ""
    var start: Date = Date(timeIntervalSince1970: 0)
    var end: Date = Date(timeIntervalSince1970: 0)
    var isAllDay: Bool = false
    var location: String = ""
    var notes: String = ""
    var calendarName: String = ""
    /// Účastníci (mená a e-maily) ako text.
    var attendeesText: String = ""
    var meetingURL: String = ""
    var searchKey: String = ""
    var attendees: ToMany<Person> = nil

    required init() {}
}

/// Nesplnená pripomienka.
// objectbox: entity
class ReminderItem {
    var id: Id = 0
    // objectbox: unique
    var identifier: String = ""
    var title: String = ""
    var notes: String = ""
    var listName: String = ""
    var due: Date? = nil
    var priority: Int = 0
    var searchKey: String = ""

    required init() {}
}
