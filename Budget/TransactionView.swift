//
//  TransactionView.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

@available(iOS 16.0, *)
struct TransactionView: View {
	@State private var amount: String = ""
	@State private var selectedCategory: Transaction.Category = .groceries
    @State private var selectedDate: Date = Date()
	@State private var description: String = ""
	
	@EnvironmentObject private var stateController: StateController
	@Environment(\.presentationMode) private var presentationMode
	
	var body: some View {
		NavigationView {
            TransactionContent(amount: $amount, selectedCategory: $selectedCategory, description: $description, selectedDate: $selectedDate)
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

@available(iOS 16.0, *)
extension TransactionView {
	func addTransaction() {
        let sign = selectedCategory == .income ? 1.0 : -1.0
        let transaction = Transaction(id: Int(), amount: Double(amount)! * 100.0 * sign, date: selectedDate, description: description, category: selectedCategory, status: 1)
        print(transaction)
		stateController.add(transaction)
		dismiss()
	}
	
	func dismiss() {
		presentationMode.wrappedValue.dismiss()
	}
}

// MARK: - Content
//struct TransactionContent: View {
//	@Binding var amount: String
//	@Binding var selectedCategory: Transaction.Category
//	@Binding var description: String
//    @Binding var selectedDate: String
//    @State var date: Date = Date()
//    
//    let dateFormatter: () = DateFormatter().dateFormat = "YY-MM-dd"
//	
//	var body: some View {
//		List {
//			Amount(amount: $amount)
//			CategorySelection(selectedCatergory: $selectedCategory)
//				.buttonStyle(PlainButtonStyle())
//            DatePicker(
//                "Date",
//                selection: $selectedDate,
//                displayedComponents: [.date]
//            )
//			TextField("Description", text: $description)
//		}
//	}
//}

@available(iOS 16.0, *)
struct TransactionContent: View {
    @Binding var amount: String
    @Binding var selectedCategory: Transaction.Category
    @Binding var description: String
    @Binding var selectedDate: Date
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        List {
            Amount(amount: $amount)
            CategorySelection(selectedCatergory: $selectedCategory)
                .buttonStyle(PlainButtonStyle())
            DatePicker(
                "Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .onChange(of: selectedDate, perform: { value in
                let formattedDate = dateFormatter.string(from: value)
                selectedDate = dateFormatter.date(from: formattedDate) ?? value
            })
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

