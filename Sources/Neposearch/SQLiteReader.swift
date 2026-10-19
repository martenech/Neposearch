import AppKit
import SQLite3

/// Minimálne čítanie SQLite databáz iných aplikácií (Mail, Safari) – len na čítanie.
struct SQLiteReader {
    enum Failure: Error {
        /// Typicky chýba Full Disk Access.
        case cannotOpen(String)
        case query(String)
    }

    struct Row {
        fileprivate let statement: OpaquePointer

        func string(_ column: Int32) -> String {
            sqlite3_column_text(statement, column).map { String(cString: $0) } ?? ""
        }

        func double(_ column: Int32) -> Double { sqlite3_column_double(statement, column) }
        func int(_ column: Int32) -> Int { Int(sqlite3_column_int64(statement, column)) }
    }

    /// Spustí dotaz a pre každý riadok zavolá `body`.
    static func query(_ path: String, _ sql: String, _ body: (Row) -> Void) throws {
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK, let db else {
            let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "?"
            sqlite3_close(db)
            throw Failure.cannotOpen(message)
        }
        defer { sqlite3_close(db) }
        sqlite3_busy_timeout(db, 2000)
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw Failure.query(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        while sqlite3_step(statement) == SQLITE_ROW { body(Row(statement: statement)) }
    }
}

enum FullDiskAccess {
    static func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
