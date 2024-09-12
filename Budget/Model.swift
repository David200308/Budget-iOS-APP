//
//  Model.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import Foundation
import GRDB

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
}

struct Statistic: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: Int
    let year: String
    let month: String
    let amount: Double
}


struct Account {
    private (set) var transactions: [Transaction]
    
    func fileName() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let dbPath = documentsPath.appendingPathComponent("data.sqlite3")
        return dbPath;
    }
    
    var yearBalance: Double {
        var yearBalance = 0.0
        let todayDate = Date()
        for transaction in transactions {
            if Calendar.current.isDate(todayDate, equalTo: transaction.date, toGranularity: .year)
                && transaction.status == 1 {
                yearBalance += Double(transaction.amount)
            }
        }
        return yearBalance
    }
    
    var monthBalance: Double {
        var monthBalance = 0.0
        let todayDate = Date()
        
        for transaction in transactions {
            if Calendar.current.isDate(todayDate, equalTo: transaction.date, toGranularity: .month)
                && Calendar.current.isDate(todayDate, equalTo: transaction.date, toGranularity: .year)
                && transaction.status == 1 {
                monthBalance += Double(transaction.amount)
            }
        }
        
        do {
            let dbQueue = try DatabaseQueue(path: fileName())
            var monthFlag = false
            var yearFlag = false
            
            try dbQueue.read { db in
                let sql = "SELECT * FROM statistic WHERE year = ? AND month = ?"
                let monthRows = try Statistic.fetchCursor(db, sql: sql, arguments: [Calendar.current.component(.year, from: todayDate), Calendar.current.component(.month, from: todayDate)])
                monthFlag = try monthRows.next() != nil
                
                let yearSql = "SELECT * FROM statistic WHERE year = ? AND month = ?"
                let yearRows = try Statistic.fetchCursor(db, sql: sql, arguments: [Calendar.current.component(.year, from: todayDate), "All"])
                yearFlag = try yearRows.next() != nil
            }
            
            try dbQueue.write { db in
                if monthFlag && yearFlag {
                    let sql = "UPDATE statistic SET amount = ? WHERE year = ? AND month = ?"
                    try db.execute(sql: sql, arguments: [monthBalance, Calendar.current.component(.year, from: todayDate), Calendar.current.component(.month, from: todayDate)])
                    
                    let yearSql = "UPDATE statistic SET amount = ? WHERE year = ? AND month = ?"
                    try db.execute(sql: yearSql, arguments: [yearBalance, Calendar.current.component(.year, from: todayDate), "All"])
                    
                } else {
                    let yearSql = "INSERT INTO statistic(year, month, amount) VALUES (?, ?, ?)"
                    try db.execute(sql: yearSql, arguments: [Calendar.current.component(.year, from: todayDate), "All", yearBalance])
                    
                    let sql = "INSERT INTO statistic(year, month, amount) VALUES (?, ?, ?)"
                    try db.execute(sql: sql, arguments: [Calendar.current.component(.year, from: todayDate), Calendar.current.component(.month, from: todayDate), monthBalance])
                }
            }
            
        } catch {
            print(error)
        }
        
        return monthBalance
    }
    

    
    
    mutating func add(_ transaction: Transaction) {
        do {
            let dbQueue = try DatabaseQueue(path: fileName())
            
            let uid = transactions.count + 1
                        
            transactions.append(transaction)
            transactions[transactions.count - 1].id = uid
//            print(transactions)
            
            writeData(transaction: transaction, uid: uid)
        } catch {
            print(error)
        }
        
        func writeData(transaction: Transaction, uid: Int) {
            do {
                let dbQueue = try DatabaseQueue(path: fileName())

                try dbQueue.write { db in
                    if (transaction.category == .income) {
                        var descr = transaction.description
                        if (transaction.description == "") {
                            descr = " "
                        }
                        
                        let sql = "INSERT INTO data VALUES (?, ?, ?, ?, ?, ?)"
                        try db.execute(sql: sql, arguments: [uid, transaction.amount, transaction.date, descr, "income", 1])
                    }
                    if (transaction.category == .utilities) {
                        var descr = transaction.description
                        if (transaction.description == "") {
                            descr = " "
                        }
                        
                        let sql = "INSERT INTO data VALUES (?, ?, ?, ?, ?, ?)"
                        try db.execute(sql: sql, arguments: [uid, transaction.amount, transaction.date, descr, "utilities", 1])
                    }
                    if (transaction.category == .groceries) {
                        var descr = transaction.description
                        if (transaction.description == "") {
                            descr = " "
                        }
                        
                        let sql = "INSERT INTO data VALUES (?, ?, ?, ?, ?, ?)"
                        try db.execute(sql: sql, arguments: [uid, transaction.amount, transaction.date, descr, "groceries", 1])
                    }
                }
            } catch {
                print(error)
            }
        }
        
    }
    
    
    mutating func delete(id: Int) {
        do {
            let dbQueue = try DatabaseQueue(path: fileName())
            
            try dbQueue.write { db in
                try db.execute(
                    sql: "DELETE FROM data WHERE id = ? AND status = 1",
                    arguments: [id]
                )
            }
                        
            for index in 0..<transactions.count {
                if (transactions[index].id == id) {
                    transactions[index].status = 0
                }
            }
                        
        } catch {
            print(error)
        }
        
    }
    
    mutating func exportCSVData() -> Data? {
        do {
            let dbQueue = try DatabaseQueue(path: fileName())
            
            struct Data: Codable, FetchableRecord, PersistableRecord {
                var id: Int
                var amount: Int
                var date: Date
                var description: String
                var category: String
                var status: Int
            }

            let transaction: [Data] = try dbQueue.read { db in
                try Data.fetchAll(db, sql: "SELECT * FROM data WHERE status = 1")
            }
                        
            var csvText = "ID,Amount,Date,Description,Category,Status\n"
            for data in transaction {
                let row = "\(data.id),\(data.amount),\(data.date),\(data.description),\(data.category),\(data.status)\n"
                csvText.append(row)
            }
            
            return csvText.data(using: .utf8)
            
        } catch {
            print("Failed to export CSV:", error)
            return nil
        }
    }
    
}
