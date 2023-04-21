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
	let amount: Int
	let date: Date
	let description: String
	let category: Category
    
//    mutating func changeId() {
//        id = count()
//    }
}

struct Account {
    private (set) var transactions: [Transaction]
    var uid = 0
    
    var monthBalance: Int {
        var monthBalance = 0
        let todayDate = Date()
        for transaction in transactions {
            if (Calendar.current.isDate(todayDate, equalTo: transaction.date, toGranularity: .month) && Calendar.current.isDate(todayDate, equalTo: transaction.date, toGranularity: .year)) {
                monthBalance += transaction.amount
            }
        }
        return monthBalance
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
            
            try dbQueue.read { db in
                uid = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM data") ?? 0
            }
            
            uid += 1
            
            transactions.append(transaction)
            print(transactions)
            writeData(transaction: transaction, uid: uid)
        } catch {
            print(error)
        }
        
        func writeData(transaction: Transaction, uid: Int) {
            do {
                let dbQueue = try DatabaseQueue(path: fileName())
                
                struct Data: Codable, FetchableRecord, PersistableRecord {
                    var id: Int
                    var amount: Int
                    var date: Date
                    var description: String
                    var category: String
                }
                
                try dbQueue.write { db in
                    if (transaction.category == .income) {
                        try Data(id: uid, amount: transaction.amount, date: Date(), description: transaction.description, category: "income").insert(db)
                    }
                    if (transaction.category == .utilities) {
                        try Data(id: uid, amount: transaction.amount, date: Date(), description: transaction.description, category: "utilities").insert(db)
                    }
                    if (transaction.category == .groceries) {
                        try Data(id: uid, amount: transaction.amount, date: Date(), description: transaction.description, category: "groceries").insert(db)
                    }
                }
                
                
            } catch {
                print (error)
            }
            
        }
        
    }
}
