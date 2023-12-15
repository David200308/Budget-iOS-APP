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
        
        var isCreateDataTable = false
        var isCreateStatisticTable = false
        
        try dbQueue.read { db in
            if (try db.tableExists("data") == false) {
//                print("Data Table Not Create")
                isCreateDataTable = false
            } else {
//                print("Data Table Already Created")
                isCreateDataTable = true
            }
            
            if (try db.tableExists("statistic") == false) {
//                print("Statistic Table Not Create")
                isCreateStatisticTable = false
            } else {
//                print("Already Created")
                isCreateStatisticTable = true
            }
        }
        
        if (isCreateDataTable == false) {
            try dbQueue.write { db in
                try db.execute(
                    sql: "CREATE TABLE IF NOT EXISTS data (id INTEGER NOT NULL, amount REAL NOT NULL, date Date NOT NULL, description TEXT, category TEXT NOT NULL, status INTEGER NOT NULL, PRIMARY KEY(id))")
            }
            print("create Data table success")
        } else {
            print("Data table exist")
        }
        
        if (isCreateStatisticTable == false) {
            try dbQueue.write { db in
                try db.execute(
                    sql: "CREATE TABLE IF NOT EXISTS statistic (id INTEGER primary key, year TEXT NOT NULL, month TEXT NOT NULL, amount REAL NOT NULL)")
            }
            print("create Statistic table success")
        } else {
            print("Statistic table exist")
        }

        struct Data: Codable, FetchableRecord, PersistableRecord {
            var id: Int
            var amount: Double
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


func readStatisticData() -> [Statistic] {
    var statistics = [Statistic]()
    
    do {
        let dbQueue = try DatabaseQueue(path: fileName())
        struct StatisticData: Codable, FetchableRecord, PersistableRecord {
            var id: Int
            var year: String
            var month: String
            var amount: Double
        }
        
        let data: [StatisticData] = try dbQueue.read { db in
            try StatisticData.fetchAll(db, sql: "SELECT * FROM statistic")
        }
        
        for d in data  {
            statistics.append(Statistic(id: d.id, year: d.year, month: d.month, amount: d.amount))
        }
    } catch {
        print (error)
    }
    
    return statistics
}


struct TransactionData {
    static let transactions: [Transaction] = readData()
    static let account = Account(transactions: transactions)
}

struct StatisticData {
    static let statistics: [Statistic] = readStatisticData()
}
