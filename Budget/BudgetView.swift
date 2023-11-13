//
//  BudgetView.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import SwiftUI
import GRDB

struct BudgetView: View {
	@EnvironmentObject private var stateController: StateController
	@State private var addingNewTransaction = false
    @State private var exportFile = false
	
	var body: some View {
		NavigationView {
			AccountView(account: stateController.account)
				.navigationBarTitle("Budget")
                .navigationBarItems(trailing: Button(action: { self.addingNewTransaction = true }) {
					Image(systemName: "plus")
						.font(.title)
				})
//                .navigationBarItems(trailing: Button(action: { self.exportFile = true }) {
//                    Image(systemName: "square.and.arrow.up")
//                        .font(.title)
//                        .imageScale(.medium)
//                })
				.sheet(isPresented: $addingNewTransaction) {
					TransactionView()
						.environmentObject(self.stateController)
                }
//                .sheet(isPresented: $exportFile) {
//                    ExportView()
//                        .environmentObject(self.stateController)
//                }
		}
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
