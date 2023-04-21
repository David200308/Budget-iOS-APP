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
	@Published var account: Account = TransactionData.account
    
    func count() -> Int {
        var tempCount = 0
        do {
            let dbQueue = try DatabaseQueue(path: fileName())
            
            try dbQueue.read { db in
                tempCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM data") ?? 0
            }
        } catch {
            print(error)
        }
        return tempCount
    }
    
	func add(_ transaction: Transaction) {
        var transaction = Transaction(id: count() + 1, amount: transaction.amount, date: transaction.date, description: transaction.description, category: transaction.category)
        print("Test 2: ", transaction)
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
        
        var isCreateTable = false
        
        try dbQueue.read { db in
            if (try db.tableExists("data") == false) {
                print("Table Not Create")
                isCreateTable = false
            } else {
                print("Already Created")
                isCreateTable = true
            }
        }
        
        if (isCreateTable == false) {
            try dbQueue.write { db in
                try db.create(table: "data") { t in
                    t.column("id", .integer).notNull()
                    t.column("amount", .integer).notNull()
                    t.column("date", .date).notNull()
                    t.column("description", .text)
                    t.column("category", .text).notNull()
                }
            }
        }

        struct Data: Codable, FetchableRecord, PersistableRecord {
            var id: Int
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
                transactions.append(Transaction(id: tran.id, amount: tran.amount, date: tran.date, description: tran.description, category: .income))
            }
            if (tran.category == "utilities") {
                transactions.append(Transaction(id: tran.id, amount: tran.amount, date: tran.date, description: tran.description, category: .utilities))
            }
            if (tran.category == "groceries") {
                transactions.append(Transaction(id: tran.id, amount: tran.amount, date: tran.date, description: tran.description, category: .groceries))
            }
        }
        
        
    } catch {
        print (error)
    }
    
    print(transactions)
    
    return transactions
}

struct TransactionData {
    static let transactions: [Transaction] = readData()
    static let account = Account(transactions: transactions)
}
