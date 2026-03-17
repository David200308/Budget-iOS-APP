//
//  iCloudSettingsView.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2026 David Jiang. All rights reserved.
//

import SwiftUI

struct iCloudSettingsView: View {
    @ObservedObject private var persistence = PersistenceController.shared
    @ObservedObject private var settings    = SettingsManager.shared
    @Environment(\.presentationMode) private var presentationMode

    @State private var showRestartNotice = false
    @State private var pendingiCloudValue = false

    var body: some View {
        NavigationView {
            Form {

                // MARK: Currency
                Section(header: Text("Currency")) {
                    Picker("Currency", selection: $settings.currencyCode) {
                        ForEach(SettingsManager.currencies) { option in
                            Text("\(option.symbol)  \(option.id) — \(option.name)")
                                .tag(option.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: Timezone
                Section(header: Text("Timezone")) {
                    NavigationLink(destination: TimezonePickerView()) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(settings.selectedTimezone.displayName)
                                    .font(.body)
                                Text(SettingsManager.utcOffset(for: settings.timezoneIdentifier))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }

                // MARK: iCloud Sync
                Section(header: Text("iCloud Sync")) {
                    Toggle("Sync with iCloud", isOn: Binding(
                        get: { persistence.iCloudSyncEnabled },
                        set: { newValue in
                            pendingiCloudValue = newValue
                            showRestartNotice  = true
                        }
                    ))
                    HStack(spacing: 8) {
                        Image(systemName: persistence.iCloudSyncEnabled
                              ? "checkmark.icloud.fill" : "icloud.slash")
                            .foregroundColor(persistence.iCloudSyncEnabled ? .blue : .secondary)
                        Text(persistence.iCloudSyncEnabled
                             ? "Currency and timezone sync across devices"
                             : "Data saved locally only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(footer: Text("Currency affects display only — no exchange rate conversion is applied. Timezone is used when formatting transaction dates.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert("Restart Required", isPresented: $showRestartNotice) {
                Button("Apply") { persistence.setICloudSync(pendingiCloudValue) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(pendingiCloudValue
                    ? "iCloud sync will be enabled the next time you open the app."
                    : "iCloud sync will be disabled the next time you open the app.")
            }
        }
    }
}

// MARK: - Timezone Picker

struct TimezonePickerView: View {
    @ObservedObject private var settings = SettingsManager.shared

    private var grouped: [(region: String, options: [SettingsManager.TimezoneOption])] {
        let regions = SettingsManager.timezones.map { $0.region }
        let unique  = regions.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        return unique.map { region in
            (region, SettingsManager.timezones.filter { $0.region == region })
        }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.region) { group in
                Section(header: Text(group.region)) {
                    ForEach(group.options) { option in
                        Button(action: { settings.timezoneIdentifier = option.id }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text(SettingsManager.utcOffset(for: option.id))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if settings.timezoneIdentifier == option.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Timezone")
        .navigationBarTitleDisplayMode(.inline)
    }
}
