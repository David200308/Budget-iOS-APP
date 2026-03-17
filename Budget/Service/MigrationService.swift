//
//  MigrationService.swift
//  Budget
//
//  Performs a one-time migration of the legacy GRDB SQLite database
//  (data.sqlite3) into Core Data on first launch after this update.
//

import Foundation
import CoreData
import SQLite3

struct MigrationService {

    /// Migrates legacy SQLite data into Core Data if not already done.
    /// Safe to call on every launch — exits immediately after the first run.
    static func migrateIfNeeded(into context: NSManagedObjectContext) {
        guard !UserDefaults.standard.bool(forKey: "coreDataMigrationDone") else { return }

        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dbPath = (documentsPath as NSString).appendingPathComponent("data.sqlite3")

        guard FileManager.default.fileExists(atPath: dbPath) else {
            markDone()
            return
        }

        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            print("Migration: could not open legacy database")
            markDone()
            return
        }
        defer { sqlite3_close(db) }

        // Verify the data table exists before querying it
        var tableCheck: OpaquePointer?
        let checkSQL = "SELECT name FROM sqlite_master WHERE type='table' AND name='data'"
        guard sqlite3_prepare_v2(db, checkSQL, -1, &tableCheck, nil) == SQLITE_OK,
              sqlite3_step(tableCheck) == SQLITE_ROW else {
            sqlite3_finalize(tableCheck)
            markDone()
            return
        }
        sqlite3_finalize(tableCheck)

        var statement: OpaquePointer?
        let query = "SELECT id, amount, date, description, category, status FROM data"
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("Migration: failed to prepare SELECT statement")
            markDone()
            return
        }
        defer { sqlite3_finalize(statement) }

        // GRDB stores dates as "YYYY-MM-DD HH:MM:SS.SSS" text in SQLite
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        fallbackFormatter.timeZone = TimeZone(identifier: "UTC")

        var count = 0
        var maxId: Int64 = 0

        while sqlite3_step(statement) == SQLITE_ROW {
            let id       = sqlite3_column_int64(statement, 0)
            let amount   = sqlite3_column_double(statement, 1)
            let dateStr  = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""
            let desc     = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? ""
            let category = sqlite3_column_text(statement, 4).map { String(cString: $0) } ?? ""
            let status   = Int16(sqlite3_column_int(statement, 5))

            let date = isoFormatter.date(from: dateStr)
                ?? fallbackFormatter.date(from: dateStr)
                ?? Date()

            let entity = CDTransaction(context: context)
            entity.localId      = id
            entity.amount       = amount
            entity.date         = date
            entity.descriptionText = desc.isEmpty ? " " : desc
            entity.category     = category
            entity.status       = status
            entity.uuid         = UUID()

            if id > maxId { maxId = id }
            count += 1
        }

        do {
            try context.save()
            // Seed the ID counter so new transactions don't collide with migrated ones
            UserDefaults.standard.set(Int(maxId), forKey: "lastTransactionId")
            markDone()
            print("Migration: imported \(count) transactions from legacy database")
        } catch {
            print("Migration: Core Data save failed — \(error)")
            context.rollback()
        }
    }

    private static func markDone() {
        UserDefaults.standard.set(true, forKey: "coreDataMigrationDone")
    }
}
