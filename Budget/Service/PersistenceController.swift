//
//  PersistenceController.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2026 David Jiang. All rights reserved.
//

import CoreData

final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    /// Whether iCloud sync is currently active. Changes take effect after app restart.
    @Published private(set) var iCloudSyncEnabled: Bool

    private init() {
        iCloudSyncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        container = NSPersistentCloudKitContainer(name: "Budget")

        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("Budget.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)

        // Required for CloudKit sync and remote change notifications
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        if iCloudSyncEnabled {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.guanlin.budget"
            )
        } else {
            description.cloudKitContainerOptions = nil
        }

        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var context: NSManagedObjectContext { container.viewContext }

    /// Saves the context if there are pending changes.
    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }

    /// Persists the iCloud sync preference. Takes effect on next app launch.
    func setICloudSync(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "iCloudSyncEnabled")
        iCloudSyncEnabled = enabled
    }
}
