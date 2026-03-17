# Budget — iOS Expense Tracker

A personal expense tracking app for iOS, built with SwiftUI and Core Data.

## Features

### Transactions

- Add, edit, and delete transactions
- Categories: Income, Groceries, Utilities
- Tap a transaction to edit, swipe left to delete
- Pull down to search by description, category, or amount

### Dashboard

- Swipeable balance banner showing Daily, Monthly, and Yearly totals
- Card-style transaction list

### Reports

- Switch between **Day**, **Month**, and **Year** views
- Navigate periods with previous/next arrows
- Summary cards: Income, Expenses, Net
- Monthly bar chart (Year view)
- Category breakdown with animated progress bars
- Monthly detail list

### CSV Import / Export

- Export all transactions to a CSV file
- Import transactions from a CSV file
- Download a CSV template to get started

### Settings

- **Currency**: Select from HKD, USD, CNY, EUR, GBP, AUD, SGD, JPY (display only)
- **Timezone**: Choose from 20+ timezones grouped by region
- **iCloud Sync**: Toggle CloudKit sync (takes effect on next launch)
- Settings sync across devices via iCloud Key-Value Store

## Tech Stack

| Layer            | Technology                                 |
| ---------------- | ------------------------------------------ |
| UI               | SwiftUI (iOS 16+)                          |
| Persistence      | Core Data + NSPersistentCloudKitContainer  |
| iCloud Sync      | CloudKit + NSUbiquitousKeyValueStore       |
| Charts           | Swift Charts                               |
| Legacy Migration | SQLite3 C API (one-time GRDB → Core Data) |

## Project Structure

```
Budget/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Model/
│   ├── Model.swift
│   ├── CDTransaction+CoreDataClass.swift
│   └── CDTransaction+CoreDataProperties.swift
├── Service/
│   ├── PersistenceController.swift
│   ├── StateController.swift
│   ├── SettingsManager.swift
│   └── MigrationService.swift
├── Utility/
│   └── Formatting.swift
├── View/
│   ├── BudgetView.swift
│   ├── TransactionView.swift
│   ├── ReportingView.swift
│   ├── CategoryView.swift
│   └── iCloudSettingsView.swift
└── Budget.xcdatamodeld/
```

## Requirements

- iOS 16.0+
- Xcode 16+
