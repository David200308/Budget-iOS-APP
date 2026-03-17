//
//  SettingsManager.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import Foundation

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // MARK: - Currency options

    struct CurrencyOption: Identifiable {
        let id: String      // ISO 4217 code
        let name: String
        let symbol: String
    }

    static let currencies: [CurrencyOption] = [
        CurrencyOption(id: "HKD", name: "Hong Kong Dollar",   symbol: "HK$"),
        CurrencyOption(id: "USD", name: "US Dollar",           symbol: "$"),
        CurrencyOption(id: "CNY", name: "Chinese Yuan",        symbol: "¥"),
        CurrencyOption(id: "EUR", name: "Euro",                symbol: "€"),
        CurrencyOption(id: "GBP", name: "British Pound",       symbol: "£"),
        CurrencyOption(id: "AUD", name: "Australian Dollar",   symbol: "A$"),
        CurrencyOption(id: "SGD", name: "Singapore Dollar",    symbol: "S$"),
        CurrencyOption(id: "JPY", name: "Japanese Yen",        symbol: "¥"),
    ]

    // MARK: - Timezone options

    struct TimezoneOption: Identifiable {
        let id: String          // TimeZone identifier
        let displayName: String
        let region: String
    }

    static let timezones: [TimezoneOption] = [
        TimezoneOption(id: "UTC",                  displayName: "UTC",            region: "UTC"),
        TimezoneOption(id: "America/New_York",      displayName: "New York",       region: "Americas"),
        TimezoneOption(id: "America/Chicago",       displayName: "Chicago",        region: "Americas"),
        TimezoneOption(id: "America/Denver",        displayName: "Denver",         region: "Americas"),
        TimezoneOption(id: "America/Los_Angeles",   displayName: "Los Angeles",    region: "Americas"),
        TimezoneOption(id: "America/Toronto",       displayName: "Toronto",        region: "Americas"),
        TimezoneOption(id: "America/Vancouver",     displayName: "Vancouver",      region: "Americas"),
        TimezoneOption(id: "Europe/London",         displayName: "London",         region: "Europe"),
        TimezoneOption(id: "Europe/Paris",          displayName: "Paris",          region: "Europe"),
        TimezoneOption(id: "Europe/Berlin",         displayName: "Berlin",         region: "Europe"),
        TimezoneOption(id: "Asia/Hong_Kong",        displayName: "Hong Kong",      region: "Asia"),
        TimezoneOption(id: "Asia/Shanghai",         displayName: "Shanghai",       region: "Asia"),
        TimezoneOption(id: "Asia/Singapore",        displayName: "Singapore",      region: "Asia"),
        TimezoneOption(id: "Asia/Tokyo",            displayName: "Tokyo",          region: "Asia"),
        TimezoneOption(id: "Asia/Seoul",            displayName: "Seoul",          region: "Asia"),
        TimezoneOption(id: "Asia/Taipei",           displayName: "Taipei",         region: "Asia"),
        TimezoneOption(id: "Asia/Dubai",            displayName: "Dubai",          region: "Asia"),
        TimezoneOption(id: "Asia/Kolkata",          displayName: "Mumbai / Delhi", region: "Asia"),
        TimezoneOption(id: "Australia/Sydney",      displayName: "Sydney",         region: "Australia"),
        TimezoneOption(id: "Australia/Melbourne",   displayName: "Melbourne",      region: "Australia"),
        TimezoneOption(id: "Australia/Perth",       displayName: "Perth",          region: "Australia"),
    ]

    // MARK: - Published settings

    @Published var currencyCode: String {
        didSet {
            UserDefaults.standard.set(currencyCode, forKey: Keys.currency)
            syncToCloud()
        }
    }

    @Published var timezoneIdentifier: String {
        didSet {
            UserDefaults.standard.set(timezoneIdentifier, forKey: Keys.timezone)
            syncToCloud()
        }
    }

    var timezone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? .current
    }

    // MARK: - Helpers

    var selectedCurrency: CurrencyOption {
        SettingsManager.currencies.first { $0.id == currencyCode }
            ?? SettingsManager.currencies[1] // fallback USD
    }

    var selectedTimezone: TimezoneOption {
        SettingsManager.timezones.first { $0.id == timezoneIdentifier }
            ?? TimezoneOption(id: timezoneIdentifier, displayName: timezoneIdentifier, region: "Other")
    }

    /// Returns a UTC offset string like "UTC+8" for display.
    static func utcOffset(for identifier: String) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return "" }
        let seconds = tz.secondsFromGMT()
        let hours   = abs(seconds) / 3600
        let minutes = (abs(seconds) % 3600) / 60
        let sign    = seconds >= 0 ? "+" : "-"
        return minutes == 0
            ? "UTC\(sign)\(hours)"
            : String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }

    // MARK: - Private

    private enum Keys {
        static let currency = "selectedCurrency"
        static let timezone = "selectedTimezone"
    }

    private init() {
        currencyCode        = UserDefaults.standard.string(forKey: Keys.currency) ?? "USD"
        timezoneIdentifier  = UserDefaults.standard.string(forKey: Keys.timezone) ?? TimeZone.current.identifier

        // Pull latest preferences from iCloud on launch
        NSUbiquitousKeyValueStore.default.synchronize()
        pullFromCloud()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
    }

    private func syncToCloud() {
        guard PersistenceController.shared.iCloudSyncEnabled else { return }
        let store = NSUbiquitousKeyValueStore.default
        store.set(currencyCode,       forKey: Keys.currency)
        store.set(timezoneIdentifier, forKey: Keys.timezone)
        store.synchronize()
    }

    private func pullFromCloud() {
        guard PersistenceController.shared.iCloudSyncEnabled else { return }
        let store = NSUbiquitousKeyValueStore.default
        if let currency = store.string(forKey: Keys.currency) { currencyCode       = currency }
        if let tz       = store.string(forKey: Keys.timezone)  { timezoneIdentifier = tz }
    }

    @objc private func cloudDidChange(_ notification: Notification) {
        DispatchQueue.main.async { self.pullFromCloud() }
    }
}
