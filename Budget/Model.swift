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

struct Account {
    private (set) var transactions: [Transaction]
    
    var monthBalance: Double {
        var monthBalance = 0.0
        let todayDate = Date()
        for transaction in transactions {
            if (Calendar.current.isDate(todayDate, equalTo: transaction.date, toGranularity: .month) && Calendar.current.isDate(todayDate, equalTo: transaction.date, toGranularity: .year) && transaction.status == 1) {
                monthBalance += Double(transaction.amount)
            }
        }
        return Double(monthBalance)
    }
    
//    var yearBalance: Int {
//        var yearBalance = 0
//        let todayDate = Date()
//        for transaction in transactions {
//            if (Calendar.current.isDate(todayDate, equalTo: transaction.date, toGranularity: .year)) {
//                yearBalance += transaction.amount
//            }
//        }
//        return yearBalance
//    }
    
    func fileName() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let dbPath = documentsPath.appendingPathComponent("data.sqlite3")
        return dbPath;
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
    
//    mutating func exportCSV() {
//        do {
//            let dbQueue = try DatabaseQueue(path: fileName())
//
//            struct Data: Codable, FetchableRecord, PersistableRecord {
//                var id: Int
//                var amount: Int
//                var date: Date
//                var description: String
//                var category: String
//                var status: Int
//            }
//
//            let transaction: [Data] = try dbQueue.read { db in
//                try Data.fetchAll(db, sql: "SELECT * FROM data WHERE status = 0")
//            }
//
//            // Create a CSV file path
//            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("transactions.csv")
//
//            // Prepare the CSV data
//            var csvText = "ID,Amount,Date,Description,Category,Status\n"
//            for data in transaction {
//                let row = "\(data.id),\(data.amount),\(data.date),\(data.description),\(data.category),\(data.status)\n"
//                csvText.append(row)
//            }
//
//            // Write the CSV data to the file
//            try csvText.write(to: fileURL!, atomically: true, encoding: .utf8)
//
//            print("CSV file exported successfully.")
//
//        } catch {
//            print(error)
//        }
//    }
//    
}
