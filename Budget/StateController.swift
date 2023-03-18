//
//  StateController.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import Foundation
import GRDB

final class StateController : ObservableObject {
	@Published var account: Account = TestData.account
    	
	func add(_ transaction: Transaction) {
		account.add(transaction)
    }
}

let section = 0
var transactions = [Transaction]()

func fileName() -> String {
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    let dbPath = documentsPath.appendingPathComponent("data.sqlite3")
    return dbPath;
}

func readData() -> [Transaction] {
    do {
        let dbQueue = try DatabaseQueue(path: fileName())
        
        
        try dbQueue.write { db in
            try db.create(table: "data") { t in
                t.column("amount", .integer).notNull()
                t.column("date", .date).notNull()
                t.column("description", .text)
                t.column("category", .text).notNull()
            }
        }

        struct Data: Codable, FetchableRecord, PersistableRecord {
            var amount: Int
            var date: Date
            var description: String
            var category: String
        }

        
        let transaction: [Data] = try dbQueue.read { db in
            try Data.fetchAll(db, sql: "SELECT * FROM data")
        }
        
        print(transaction)
        
        for tran in transaction  {
            if (tran.category == "income") {
                transactions.append(Transaction(amount: tran.amount, date: tran.date, description: tran.description, category: .income))
            }
            if (tran.category == "utilities") {
                transactions.append(Transaction(amount: tran.amount, date: tran.date, description: tran.description, category: .utilities))
            }
            if (tran.category == "groceries") {
                transactions.append(Transaction(amount: tran.amount, date: tran.date, description: tran.description, category: .groceries))
            }
        }
        
        
    } catch {
        print (error)
    }
    
    return transactions
}

struct TestData {
    static let transactions: [Transaction] = readData()
    static let account = Account(transactions: transactions)
}
