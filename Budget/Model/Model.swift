//
//  Model.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2026 David Jiang. All rights reserved.
//

import Foundation

// MARK: - Transaction

struct Transaction: Identifiable {
    enum Category: String, CaseIterable, Identifiable {
        case income, groceries, utilities
        var id: String { rawValue }
    }

    var id: Int
    let amount: Double
    let date: Date
    let description: String
    let category: Category
    var status: Int

    init(id: Int, amount: Double, date: Date, description: String, category: Category, status: Int) {
        self.id = id
        self.amount = amount
        self.date = date
        self.description = description
        self.category = category
        self.status = status
    }

    /// Maps a Core Data entity to a Transaction value. Returns nil if required fields are missing.
    init?(from entity: CDTransaction) {
        guard let categoryStr = entity.category,
              let category = Category(rawValue: categoryStr),
              let date = entity.date else { return nil }
        self.id = Int(entity.localId)
        self.amount = entity.amount
        self.date = date
        self.description = entity.descriptionText ?? ""
        self.category = category
        self.status = Int(entity.status)
    }
}

// MARK: - Statistic (computed, not persisted)

struct Statistic: Identifiable {
    var id: Int
    let year: String
    let month: String
    let amount: Double
}

// MARK: - Account

struct Account {
    private(set) var transactions: [Transaction]

    // MARK: Balances

    var dayBalance: Double {
        let today = Date()
        return transactions
            .filter { $0.status == 1 && Calendar.current.isDate(today, equalTo: $0.date, toGranularity: .day) }
            .reduce(0) { $0 + $1.amount }
    }

    var monthBalance: Double {
        let today = Date()
        return transactions
            .filter {
                $0.status == 1
                    && Calendar.current.isDate(today, equalTo: $0.date, toGranularity: .month)
                    && Calendar.current.isDate(today, equalTo: $0.date, toGranularity: .year)
            }
            .reduce(0) { $0 + $1.amount }
    }

    var yearBalance: Double {
        let year = Calendar.current.component(.year, from: Date())
        return transactions
            .filter { $0.status == 1 && Calendar.current.component(.year, from: $0.date) == year }
            .reduce(0) { $0 + $1.amount }
    }

    var dayTransactionCount: Int {
        let today = Date()
        return transactions
            .filter { $0.status == 1 && Calendar.current.isDate(today, equalTo: $0.date, toGranularity: .day) }
            .count
    }

    var monthTransactionCount: Int {
        let today = Date()
        return transactions
            .filter {
                $0.status == 1
                    && Calendar.current.isDate(today, equalTo: $0.date, toGranularity: .month)
                    && Calendar.current.isDate(today, equalTo: $0.date, toGranularity: .year)
            }
            .count
    }

    var yearTransactionCount: Int {
        let year = Calendar.current.component(.year, from: Date())
        return transactions
            .filter { $0.status == 1 && Calendar.current.component(.year, from: $0.date) == year }
            .count
    }

    // MARK: Statistics (grouped by month and year)

    var statistics: [Statistic] {
        var monthlyAmounts: [String: (year: String, month: String, amount: Double)] = [:]
        var yearlyAmounts: [String: Double] = [:]

        for t in transactions where t.status == 1 {
            let year  = String(Calendar.current.component(.year,  from: t.date))
            let month = String(Calendar.current.component(.month, from: t.date))
            let key   = "\(year)-\(month)"
            monthlyAmounts[key] = (
                year: year,
                month: month,
                amount: (monthlyAmounts[key]?.amount ?? 0) + t.amount
            )
            yearlyAmounts[year, default: 0] += t.amount
        }

        var result: [Statistic] = []
        var idCounter = 1

        for (_, stat) in monthlyAmounts.sorted(by: { $0.key < $1.key }) {
            result.append(Statistic(id: idCounter, year: stat.year, month: stat.month, amount: stat.amount))
            idCounter += 1
        }
        for (year, amount) in yearlyAmounts.sorted(by: { $0.key < $1.key }) {
            result.append(Statistic(id: idCounter, year: year, month: "All", amount: amount))
            idCounter += 1
        }
        return result
    }

    // MARK: Mutations (in-memory; persistence is handled by StateController)

    mutating func append(_ transaction: Transaction) {
        transactions.append(transaction)
    }

    mutating func remove(id: Int) {
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions.remove(at: index)
        }
    }

    mutating func update(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
        }
    }

    // MARK: CSV Export

    mutating func exportCSVData() -> Data? {
        var csv = "ID,Amount,Date,Description,Category,Status\n"
        for t in transactions where t.status == 1 {
            let amount = String(format: "%.2f", t.amount / 100.0)
            let date   = DateFormatter.localizedString(from: t.date, dateStyle: .short, timeStyle: .none)
            csv.append("\(t.id),\(amount),\(date),\(t.description),\(t.category.rawValue),\(t.status)\n")
        }
        return csv.data(using: .utf8)
    }
}
