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
    var status: Int
}

struct Account {
    private (set) var transactions: [Transaction]
    
    var monthBalance: Int {
        var monthBalance = 0
        let todayDate = Date()
        for transaction in transactions {
            if (Calendar.current.isDate(todayDate, equalTo: transaction.date, toGranularity: .month) && Calendar.current.isDate(todayDate, equalTo: transaction.date, toGranularity: .year) && transaction.status == 1) {
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
                            descr = "N/A"
                        }
                        
                        try db.execute(
                            sql: "INSERT INTO data VALUES(" + String(uid) + ", " + String(transaction.amount) +  ", date('now'), '" + descr + "', 'income', 1)")
                    }
                    if (transaction.category == .utilities) {
                        var descr = transaction.description
                        if (transaction.description == "") {
                            descr = "N/A"
                        }
                        try db.execute(
                            sql: "INSERT INTO data VALUES(" + String(uid) + ", " + String(transaction.amount) +  ", date('now'), '" + descr + "', 'utilities', 1)")
                    }
                    if (transaction.category == .groceries) {
                        var descr = transaction.description
                        if (transaction.description == "") {
                            descr = "N/A"
                        }
                        try db.execute(
                            sql: "INSERT INTO data VALUES(" + String(uid) + ", " + String(transaction.amount) +  ", date('now'), '" + descr + "', 'groceries', 1)")
                    }
                }
                                
            } catch {
                print (error)
            }
            
        }
        
    }
    
    
    mutating func delete(id: Int) {
        do {
            let dbQueue = try DatabaseQueue(path: fileName())
            
            try dbQueue.write { db in
                try db.execute(
                    sql: "UPDATE data SET status = 0 WHERE id = " + String(id) + " AND status = 1")
            }
            
//            print(transactions)
            
            for index in 0..<transactions.count {
                if (transactions[index].id == id) {
                    transactions[index].status = 0
                }
            }
                        
        } catch {
            print(error)
        }
        
    }
    
}
