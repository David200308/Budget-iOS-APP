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
	
	let id = UUID()
	let amount: Int
	let date: Date
	let description: String
	let category: Category
}

struct Account {
	private (set) var transactions: [Transaction]
    var uid = 0
	
	var balance: Int {
		var balance = 0
		for transaction in transactions {
			balance += transaction.amount
		}
		return balance
	}
	
	mutating func add(_ transaction: Transaction) {
        uid += 1
		transactions.append(transaction)
        writeData(transaction: transaction, uid: uid)
	}
    
    func fileName() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let dbPath = documentsPath.appendingPathComponent("data.sqlite3")
        return dbPath;
    }
    
    func writeData(transaction: Transaction, uid: Int) {
        do {
            let dbQueue = try DatabaseQueue(path: fileName())
            
            struct Data: Codable, FetchableRecord, PersistableRecord {
                var amount: Int
                var date: Date
                var description: String
                var category: String
            }
                        
            try dbQueue.write { db in
                if (transaction.category == .income) {
                    try Data(amount: transaction.amount, date: Date(), description: transaction.description, category: "income").insert(db)
                }
                if (transaction.category == .utilities) {
                    try Data(amount: transaction.amount, date: Date(), description: transaction.description, category: "utilities").insert(db)
                }
                if (transaction.category == .groceries) {
                    try Data(amount: transaction.amount, date: Date(), description: transaction.description, category: "groceries").insert(db)
                }
            }
            

        } catch {
            print (error)
        }
        
    }
    

}
