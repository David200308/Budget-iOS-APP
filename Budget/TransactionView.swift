//
//  TransactionView.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct TransactionView: View {
	@State private var amount: String = ""
	@State private var selectedCategory: Transaction.Category = .groceries
	@State private var description: String = ""
	
	@EnvironmentObject private var stateController: StateController
	@Environment(\.presentationMode) private var presentationMode
	
	var body: some View {
		NavigationView {
			TransactionContent(amount: $amount, selectedCategory: $selectedCategory, description: $description)
				.navigationBarTitle("New Transaction")
				.navigationBarItems(leading: Button(action: { self.dismiss() }) {
					Text("Cancel")
					}, trailing: Button(action: addTransaction) {
						Text("Add")
							.bold()
				})
		}
	}
}

private extension TransactionView {
	func addTransaction() {
        let sign = selectedCategory == .income ? 1.0 : -1.0
        let transaction = Transaction(id: Int(), amount: Double(amount)! * 100.0 * sign, date: Date(), description: description, category: selectedCategory, status: 1)
		stateController.add(transaction)
		dismiss()
	}
	
	func dismiss() {
		presentationMode.wrappedValue.dismiss()
	}
}

// MARK: - Content
struct TransactionContent: View {
	@Binding var amount: String
	@Binding var selectedCategory: Transaction.Category
	@Binding var description: String
	
	var body: some View {
		List {
			Amount(amount: $amount)
			CategorySelection(selectedCatergory: $selectedCategory)
				.buttonStyle(PlainButtonStyle())
			TextField("Description", text: $description)
		}
	}
}

// MARK: - Amount
struct Amount: View {
	@Binding var amount: String
	
	var body: some View {
		VStack(alignment: .trailing) {
			Text("Amount")
				.font(.callout)
				.bold()
				.foregroundColor(.secondary)
            TextField(Double(0).currencyFormat, text: $amount)
				.multilineTextAlignment(.trailing)
				.keyboardType(.decimalPad)
				.font(Font.largeTitle.bold())
		}
		.padding()
	}
}

// MARK: - Selection
struct CategorySelection: View {
	@Binding var selectedCatergory: Transaction.Category
	
	var body: some View {
		HStack {
			Spacer()
			ForEach(Transaction.Category.allCases) { category in
				CategoryButton(category: category, selected: category == self.selectedCatergory, action: { self.selectedCatergory = category })
				Spacer()
			}
		}
		.padding()
	}
}

// MARK: - Category
struct CategoryButton: View {
	let category: Transaction.Category
	var selected: Bool = false
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			VStack {
				CategoryView(category: category, highlighted: selected)
				Text(category.name)
					.font(.headline)
					.foregroundColor(selected ? .primary : .secondary)
			}
		}
	}
}

// MARK: - Previews
struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
		Group {
			TransactionView()
			TransactionContent(amount: .constant(""), selectedCategory: .constant(.groceries), description: .constant(""))
			Group {
				Amount(amount: .constant(""))
				CategorySelection(selectedCatergory: .constant(.groceries))
				HStack {
					CategoryButton(category: .groceries, action: {})
					CategoryButton(category: .groceries, selected: true, action: {})
				}
				.padding()
			}
			.previewLayout(.sizeThatFits)
		}
    }
}
