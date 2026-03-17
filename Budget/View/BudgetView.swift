//
//  BudgetView.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

@available(iOS 16.0, *)
struct BudgetView: View {
    @EnvironmentObject private var stateController: StateController
    @State private var addingNewTransaction = false
    @State private var showReporting        = false
    @State private var showSettings         = false

    // Export
    @State private var showFileExporter = false
    @State private var csvData: Data?   = nil

    // Import
    @State private var showFileImporter  = false
    @State private var showImportResult  = false
    @State private var importedCount     = 0
    @State private var showImportError   = false

    var body: some View {
        NavigationView {
            AccountView(account: stateController.account)
                .navigationTitle("Expense")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {

                        // Data menu: export / import / template
                        Menu {
                            Button(action: exportCSV) {
                                Label("Export CSV", systemImage: "square.and.arrow.up")
                            }
                            Button(action: { showFileImporter = true }) {
                                Label("Import CSV", systemImage: "square.and.arrow.down")
                            }
                            Button(action: exportTemplate) {
                                Label("Download Template", systemImage: "doc.badge.plus")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title)
                                .imageScale(.medium)
                        }

                        Button(action: { showReporting = true }) {
                            Image(systemName: "doc.fill")
                                .font(.title)
                                .imageScale(.medium)
                        }

                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                                .font(.title)
                                .imageScale(.medium)
                        }

                        Button(action: { addingNewTransaction = true }) {
                            Image(systemName: "plus")
                                .font(.title)
                        }
                    }
                }
                // Add transaction
                .sheet(isPresented: $addingNewTransaction) {
                    TransactionView().environmentObject(stateController)
                }
                // Report
                .sheet(isPresented: $showReporting) {
                    ReportingView().environmentObject(stateController)
                }
                // iCloud settings
                .sheet(isPresented: $showSettings) {
                    iCloudSettingsView()
                }
                // Export CSV
                .fileExporter(
                    isPresented: $showFileExporter,
                    document: CSVDocument(data: csvData ?? Data()),
                    contentType: .commaSeparatedText,
                    defaultFilename: "transactions_\(Date().exportFilename)"
                ) { result in
                    if case .failure(let error) = result {
                        print("Export failed: \(error.localizedDescription)")
                    }
                }
                // Import CSV
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: [.commaSeparatedText],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        importCSV(from: url)
                    case .failure(let error):
                        print("Import picker failed: \(error.localizedDescription)")
                        showImportError = true
                    }
                }
                // Import result alert
                .alert("Import Complete", isPresented: $showImportResult) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Successfully imported \(importedCount) transaction(s).")
                }
                .alert("Import Failed", isPresented: $showImportError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("The file could not be read or contained no valid transactions. Please check the format matches the template.")
                }
        }
    }

    // MARK: - Export

    private func exportCSV() {
        csvData = stateController.account.exportCSVData()
        showFileExporter = csvData != nil
    }

    private func exportTemplate() {
        let template = """
        Amount,Date,Description,Category
        500.00,01/01/2024,Monthly salary,income
        -12.50,01/15/2024,Grocery shopping,groceries
        -50.00,01/20/2024,Electric bill,utilities
        """
        csvData = template.data(using: .utf8)
        showFileExporter = true
    }

    // MARK: - Import

    private func importCSV(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            showImportError = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            showImportError = true
            return
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            showImportError = true
            return
        }

        let headers = lines[0]
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

        guard let amountIdx   = headers.firstIndex(of: "amount"),
              let dateIdx     = headers.firstIndex(of: "date"),
              let categoryIdx = headers.firstIndex(of: "category") else {
            showImportError = true
            return
        }
        let descIdx = headers.firstIndex(of: "description")

        // Try multiple date formats
        let dateFormatters: [DateFormatter] = ["MM/dd/yyyy", "dd/MM/yyyy", "yyyy-MM-dd"].map {
            let f = DateFormatter()
            f.dateFormat = $0
            return f
        }
        func parseDate(_ str: String) -> Date? {
            dateFormatters.lazy.compactMap { $0.date(from: str) }.first
        }

        var imported = 0
        for line in lines.dropFirst() {
            let fields = line.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            let maxIdx = max(amountIdx, dateIdx, categoryIdx)
            guard fields.count > maxIdx else { continue }

            guard let amount   = Double(fields[amountIdx]),
                  let date     = parseDate(fields[dateIdx]),
                  let category = Transaction.Category(rawValue: fields[categoryIdx].lowercased())
            else { continue }

            let desc = descIdx.flatMap { fields.indices.contains($0) ? fields[$0] : nil } ?? ""

            // Amount is stored in cents. CSV amounts are already signed.
            let transaction = Transaction(
                id: 0,
                amount: amount * 100.0,
                date: date,
                description: desc,
                category: category,
                status: 1
            )
            stateController.add(transaction)
            imported += 1
        }

        if imported > 0 {
            importedCount = imported
            showImportResult = true
        } else {
            showImportError = true
        }
    }
}

// MARK: - AccountView

struct AccountView: View {
    @EnvironmentObject private var stateController: StateController
    let account: Account

    private var transactions: [Transaction] {
        account.transactions
            .filter { $0.status == 1 }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Balance(monthAmount: account.monthBalance)
            ForEach(transactions) { transaction in
                Row(transaction: transaction)
            }
            .onDelete { indexSet in
                indexSet.forEach { stateController.delete(id: transactions[$0].id) }
            }
        }
    }
}

// MARK: - Balance

struct Balance: View {
    var monthAmount: Double

    var body: some View {
        VStack(alignment: .leading) {
            Text("Monthly Balance")
                .font(.callout)
                .bold()
                .foregroundColor(.secondary)
            Text(monthAmount.currencyFormat)
                .font(.system(size: 30))
                .bold()
        }
        .padding(.vertical)
    }
}

// MARK: - Row

struct Row: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 16.0) {
            CategoryView(category: transaction.category)
            VStack(alignment: .leading, spacing: 4.0) {
                Text(transaction.category.name)
                    .font(.headline)
                Text(transaction.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4.0) {
                Text(transaction.amount.currencyFormat)
                    .font(.headline)
                    .foregroundColor(transaction.amount > 0 ? .blue : .primary)
                Text(transaction.date.transactionFormat)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - CSV Document

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}

// MARK: - Date export filename helper

private extension Date {
    var exportFilename: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
}
