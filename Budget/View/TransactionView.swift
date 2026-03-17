//
//  TransactionView.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2026 David Jiang. All rights reserved.
//

import SwiftUI

struct TransactionView: View {
    let editing: Transaction?

    @State private var amount: String
    @State private var selectedCategory: Transaction.Category
    @State private var selectedDate: Date
    @State private var description: String
    @State private var showAmountAlert = false

    @EnvironmentObject private var stateController: StateController
    @Environment(\.presentationMode) private var presentationMode

    init(editing: Transaction? = nil) {
        self.editing = editing
        if let t = editing {
            _amount           = State(initialValue: String(format: "%.2f", abs(t.amount) / 100.0))
            _selectedCategory = State(initialValue: t.category)
            _selectedDate     = State(initialValue: t.date)
            _description      = State(initialValue: t.description)
        } else {
            _amount           = State(initialValue: "")
            _selectedCategory = State(initialValue: .groceries)
            _selectedDate     = State(initialValue: Date())
            _description      = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationView {
            TransactionContent(
                amount: $amount,
                selectedCategory: $selectedCategory,
                description: $description,
                selectedDate: $selectedDate
            )
            .navigationBarTitle(editing == nil ? "New Transaction" : "Edit Transaction")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button(editing == nil ? "Add" : "Save") { save() }.bold()
            )
            .alert("Invalid Amount", isPresented: $showAmountAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a valid amount greater than zero.")
            }
        }
    }

    private func save() {
        guard let value = Double(amount), value > 0 else {
            showAmountAlert = true
            return
        }
        let sign = selectedCategory == .income ? 1.0 : -1.0
        if let existing = editing {
            stateController.update(Transaction(
                id: existing.id, amount: value * 100.0 * sign,
                date: selectedDate, description: description,
                category: selectedCategory, status: 1
            ))
        } else {
            stateController.add(Transaction(
                id: 0, amount: value * 100.0 * sign,
                date: selectedDate, description: description,
                category: selectedCategory, status: 1
            ))
        }
        dismiss()
    }

    private func dismiss() { presentationMode.wrappedValue.dismiss() }
}

// MARK: - Content

struct TransactionContent: View {
    @Binding var amount: String
    @Binding var selectedCategory: Transaction.Category
    @Binding var description: String
    @Binding var selectedDate: Date

    var body: some View {
        List {
            Amount(amount: $amount)
            CategorySelection(selectedCatergory: $selectedCategory)
                .buttonStyle(PlainButtonStyle())
            DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
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

// MARK: - Category Selection

struct CategorySelection: View {
    @Binding var selectedCatergory: Transaction.Category

    var body: some View {
        HStack {
            Spacer()
            ForEach(Transaction.Category.allCases) { category in
                CategoryButton(
                    category: category,
                    selected: category == selectedCatergory,
                    action: { selectedCatergory = category }
                )
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Category Button

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
