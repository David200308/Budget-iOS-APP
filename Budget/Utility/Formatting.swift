//
//  Formatting.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import Foundation

extension Double {
    /// Formats as currency using the given ISO currency code.
    /// Pass `settings.currencyCode` in SwiftUI views to create a reactive dependency.
    func currencyFormat(code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: NSNumber(value: self / 100)) ?? ""
    }

    /// Convenience — reads from SettingsManager.shared.
    /// Use `currencyFormat(code:)` inside SwiftUI views so the view re-renders on change.
    var currencyFormat: String {
        currencyFormat(code: SettingsManager.shared.currencyCode)
    }
}

extension Date {
    /// Formats as a medium date string using the given timezone.
    /// Pass `settings.timezone` in SwiftUI views to create a reactive dependency.
    func transactionFormat(timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone  = timezone
        return formatter.string(from: self)
    }

    /// Convenience — reads from SettingsManager.shared.
    var transactionFormat: String {
        transactionFormat(timezone: SettingsManager.shared.timezone)
    }
}

extension Transaction.Category {
    var name: String { rawValue.capitalized }

    var imageName: String {
        switch self {
        case .groceries: return "cart.fill"
        case .income:    return "hand.thumbsup.fill"
        case .utilities: return "phone.fill"
        }
    }
}
