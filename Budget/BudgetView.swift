//
//  BudgetView.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import SwiftUI
import GRDB
import UniformTypeIdentifiers

@available(iOS 16.0, *)
struct BudgetView: View {
    @EnvironmentObject private var stateController: StateController
    @State private var addingNewTransaction = false
    @State private var monthReporting = false
    @State private var exportFile = false
    @State private var csvData: Data? = nil
    @State private var showFileExporter = false

    var body: some View {
            NavigationView {
                AccountView(account: stateController.account)
                    .navigationTitle("Budget")
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button(action: exportCSV) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title)
                                    .imageScale(.medium)
                            }
                            
                            Button(action: { self.monthReporting = true }) {
                                Image(systemName: "doc.fill")
                                    .font(.title)
                                    .imageScale(.medium)
                            }
                            
                            Button(action: { self.addingNewTransaction = true }) {
                                Image(systemName: "plus")
                                    .font(.title)
                            }
                        }
                    }
                    .sheet(isPresented: $addingNewTransaction) {
                        TransactionView()
                            .environmentObject(self.stateController)
                    }
                    .sheet(isPresented: $monthReporting) {
                        ReportingView()
                            .environmentObject(self.stateController)
                    }
                    .fileExporter(
                        isPresented: $showFileExporter,
                        document: CSVDocument(data: csvData ?? Data()),
                        contentType: .commaSeparatedText,
                        defaultFilename: "transactions"
                    ) { result in
                        switch result {
                        case .success(let url):
                            print("File saved to: \(url)")
                        case .failure(let error):
                            print("Failed to save file: \(error.localizedDescription)")
                        }
                    }
            }
        }
    
    private func exportCSV() {
        csvData = stateController.account.exportCSVData()
        showFileExporter = csvData != nil
    }
}

// MARK: - AccountView
struct AccountView: View {
    @EnvironmentObject private var stateController: StateController
    let account: Account
    
    private var transactions: [Budget.Transaction] {
        return account
            .transactions
            .sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        List {
            Balance(monthAmount: Double(account.monthBalance))
            ForEach(transactions.indices, id: \.self) { index in
                if transactions[index].status == 1 {
                    Row(transaction: transactions[index])
                }
            }
            .onDelete(perform: { indexSet in
                indexSet.forEach { index in
                    stateController.delete(id: transactions[index].id)
                }
            })
        }
    }
}

// MARK: - Balance
struct Balance: View {
	var monthAmount: Double
//    var yearAmount: Int
	
	var body: some View {
//        HStack {
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
//            VStack(alignment: .leading) {
//                Text("Yearly Balance")
//                    .font(.callout)
//                    .bold()
//                    .foregroundColor(.secondary)
//                Text(yearAmount.currencyFormat)
//                    .font(.system(size: 30))
//                    .bold()
//            }
//            .padding(.vertical)
//        }
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
                    .foregroundColor(color(for: Int(transaction.amount)))
				Text(transaction.date.transactionFormat)
					.font(.caption)
					.foregroundColor(.secondary)
			}
		}
		.padding(.vertical)
	}
	
	func color(for amount: Int) -> Color {
		amount > 0 ? .blue : .primary
	}
}

// MARK: - CSV Document
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: data)
    }
}

//// MARK: - Previews
//struct BudgetView_Previews: PreviewProvider {
//	static let account = TransactionData.account
//	
//    static var previews: some View {
//		Group {
//            AccountView(account: account)
//			Group {
//                Balance(monthAmount: account.monthBalance)
////                ForEach(account.transactions, id: \.self){ transaction in
////                    Row(transaction: transaction)
////                }
////                Row(transaction: account.transactions)
//			}
//			.previewLayout(.sizeThatFits)
//		}
//    }
//}
