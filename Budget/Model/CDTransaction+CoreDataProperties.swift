//
//  CDTransaction+CoreDataProperties.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import Foundation
import CoreData

extension CDTransaction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTransaction> {
        return NSFetchRequest<CDTransaction>(entityName: "CDTransaction")
    }

    @NSManaged public var amount: Double
    @NSManaged public var category: String?
    @NSManaged public var date: Date?
    @NSManaged public var descriptionText: String?
    @NSManaged public var localId: Int64
    @NSManaged public var status: Int16
    @NSManaged public var uuid: UUID?
}

extension CDTransaction: Identifiable {}
