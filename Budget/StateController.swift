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
        let transaction = Transaction(id: count() + 1, amount: transaction.amount, date: transaction.date, description: transaction.description, category: transaction.category, status: transaction.status)
//        print("Test 2: ", transaction)
        account.add(transaction)
    }
    
    func delete(id: Int) {
        account.delete(id: id)
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
                try db.execute(
                    sql: "CREATE TABLE IF NOT EXISTS data (id INT NOT NULL, amount INT NOT NULL, date Date NOT NULL, description TEXT, category TEXT NOT NULL, status INTEGER NOT NULL, PRIMARY KEY(id))")
            }
            print("create table success")
        } else {
            print("table exist")
        }

        struct Data: Codable, FetchableRecord, PersistableRecord {
            var id: Int
            var amount: Int
            var date: Date
            var description: String
            var category: String
            var status: Int
        }

        
        let transaction: [Data] = try dbQueue.read { db in
            try Data.fetchAll(db, sql: "SELECT * FROM data")
        }
        
//        print(transaction)
        
        for tran in transaction  {
            if (tran.category == "income") {
                transactions.append(Transaction(id: tran.id, amount: tran.amount, date: tran.date, description: tran.description, category: .income, status: tran.status))
            }
            if (tran.category == "utilities") {
                transactions.append(Transaction(id: tran.id, amount: tran.amount, date: tran.date, description: tran.description, category: .utilities, status: tran.status))
            }
            if (tran.category == "groceries") {
                transactions.append(Transaction(id: tran.id, amount: tran.amount, date: tran.date, description: tran.description, category: .groceries, status: tran.status))
            }
        }
        
    } catch {
        print (error)
    }
    
    transactions = transactions.reversed()
    print(transactions)
    
    return transactions
}

struct TransactionData {
    static let transactions: [Transaction] = readData()
    static let account = Account(transactions: transactions)
}
