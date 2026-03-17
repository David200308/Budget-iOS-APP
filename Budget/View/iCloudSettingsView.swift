//
//  iCloudSettingsView.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import SwiftUI

struct iCloudSettingsView: View {
    @ObservedObject private var persistence = PersistenceController.shared
    @Environment(\.presentationMode) private var presentationMode

    @State private var showRestartNotice = false
    @State private var pendingValue = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("iCloud Sync")) {
                    Toggle("Sync with iCloud", isOn: Binding(
                        get: { persistence.iCloudSyncEnabled },
                        set: { newValue in
                            pendingValue = newValue
                            showRestartNotice = true
                        }
                    ))
                }
                Section(footer: Text("Your transactions are always saved locally on this device. When iCloud sync is on, data is automatically kept in sync across all your Apple devices signed in to the same iCloud account.")) {
                    EmptyView()
                }
                Section(header: Text("Current status")) {
                    HStack {
                        Image(systemName: persistence.iCloudSyncEnabled ? "checkmark.icloud.fill" : "icloud.slash")
                            .foregroundColor(persistence.iCloudSyncEnabled ? .blue : .secondary)
                        Text(persistence.iCloudSyncEnabled ? "iCloud sync is on" : "iCloud sync is off")
                            .foregroundColor(persistence.iCloudSyncEnabled ? .primary : .secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert("Restart Required", isPresented: $showRestartNotice) {
                Button("Apply") {
                    persistence.setICloudSync(pendingValue)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(pendingValue
                    ? "iCloud sync will be enabled the next time you open the app."
                    : "iCloud sync will be disabled the next time you open the app."
                )
            }
        }
    }
}
