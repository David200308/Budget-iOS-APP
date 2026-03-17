//
//  StateController.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2026 David Jiang. All rights reserved.
//

import Foundation
import CoreData

final class StateController: ObservableObject {
    @Published var account: Account = Account(transactions: [])

    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext { persistence.context }

    init() {
        loadTransactions()
        initializeIdCounter()
        observeRemoteChanges()
    }

    // MARK: - Load

    func loadTransactions() {
        let request = CDTransaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        do {
            let entities = try context.fetch(request)
            account = Account(transactions: entities.compactMap { Transaction(from: $0) })
        } catch {
            print("StateController: failed to load transactions — \(error)")
        }
    }

    // MARK: - Add

    func add(_ transaction: Transaction) {
        let entity = CDTransaction(context: context)
        entity.uuid            = UUID()
        entity.localId         = Int64(nextId())
        entity.amount          = transaction.amount
        entity.date            = transaction.date
        entity.descriptionText = transaction.description.isEmpty ? " " : transaction.description
        entity.category        = transaction.category.rawValue
        entity.status          = 1
        persistence.save()

        account.append(Transaction(
            id:          Int(entity.localId),
            amount:      entity.amount,
            date:        entity.date ?? Date(),
            description: entity.descriptionText ?? "",
            category:    transaction.category,
            status:      1
        ))
    }

    // MARK: - Update

    func update(_ transaction: Transaction) {
        let request = CDTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "localId == %d", transaction.id)
        do {
            guard let entity = try context.fetch(request).first else { return }
            entity.amount          = transaction.amount
            entity.date            = transaction.date
            entity.descriptionText = transaction.description.isEmpty ? " " : transaction.description
            entity.category        = transaction.category.rawValue
            persistence.save()
            account.update(transaction)
        } catch {
            print("StateController: failed to update transaction \(transaction.id) — \(error)")
        }
    }

    // MARK: - Delete

    func delete(id: Int) {
        let request = CDTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "localId == %d", id)
        do {
            let results = try context.fetch(request)
            results.forEach { context.delete($0) }
            persistence.save()
            account.remove(id: id)
        } catch {
            print("StateController: failed to delete transaction \(id) — \(error)")
        }
    }

    // MARK: - ID generation

    /// Initialises the counter from the current maximum stored id,
    /// so new transactions never collide with migrated or existing ones.
    private func initializeIdCounter() {
        let maxId = account.transactions.map { $0.id }.max() ?? 0
        let stored = UserDefaults.standard.integer(forKey: "lastTransactionId")
        if stored < maxId {
            UserDefaults.standard.set(maxId, forKey: "lastTransactionId")
        }
    }

    private func nextId() -> Int {
        let next = UserDefaults.standard.integer(forKey: "lastTransactionId") + 1
        UserDefaults.standard.set(next, forKey: "lastTransactionId")
        return next
    }

    // MARK: - Remote changes (iCloud sync)

    private func observeRemoteChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: context.persistentStoreCoordinator
        )
    }

    @objc private func handleRemoteChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.context.refreshAllObjects()
            self.loadTransactions()
        }
    }
}
