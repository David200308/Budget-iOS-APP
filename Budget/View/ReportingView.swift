//
//  ReportingView.swift
//  Budget
//
//  Created by David Jiang on 15/12/2023.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import SwiftUI
import Charts

// MARK: - Root

struct ReportingView: View {
    @EnvironmentObject private var stateController: StateController
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedYear: String = String(Calendar.current.component(.year, from: Date()))

    private var transactions: [Transaction] {
        stateController.account.transactions.filter { $0.status == 1 }
    }

    private var availableYears: [String] {
        let years = Set(transactions.map {
            String(Calendar.current.component(.year, from: $0.date))
        })
        return years.sorted(by: >)
    }

    private var filtered: [Transaction] {
        transactions.filter {
            String(Calendar.current.component(.year, from: $0.date)) == selectedYear
        }
    }

    private var totalIncome: Double {
        filtered.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    private var totalExpenses: Double {
        filtered.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount }
    }
    private var netBalance: Double { totalIncome + totalExpenses }

    private var monthlySummaries: [MonthSummary] {
        var dict: [Int: (income: Double, expenses: Double)] = [:]
        for t in filtered {
            let m = Calendar.current.component(.month, from: t.date)
            var e = dict[m] ?? (0, 0)
            if t.amount > 0 { e.income += t.amount } else { e.expenses += t.amount }
            dict[m] = e
        }
        return dict
            .map { MonthSummary(month: $0.key, year: Int(selectedYear) ?? 0,
                                income: $0.value.income, expenses: $0.value.expenses) }
            .sorted { $0.month < $1.month }
    }

    private var categoryTotals: [(category: Transaction.Category, amount: Double)] {
        var dict: [Transaction.Category: Double] = [:]
        for t in filtered { dict[t.category, default: 0] += abs(t.amount) }
        let grandTotal = dict.values.reduce(0, +)
        guard grandTotal > 0 else { return [] }
        return Transaction.Category.allCases
            .compactMap { cat in dict[cat].map { (cat, $0) } }
            .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if availableYears.count > 1 {
                        YearPicker(years: availableYears, selected: $selectedYear)
                    }

                    if filtered.isEmpty {
                        EmptyReportView(year: selectedYear)
                    } else {
                        SummaryCards(income: totalIncome,
                                     expenses: totalExpenses,
                                     net: netBalance,
                                     currencyCode: settings.currencyCode)

                        MonthlyChart(summaries: monthlySummaries)

                        if !categoryTotals.isEmpty {
                            let grandTotal = categoryTotals.reduce(0) { $0 + $1.amount }
                            CategoryBreakdown(totals: categoryTotals, grandTotal: grandTotal)
                        }

                        MonthlyDetail(summaries: monthlySummaries)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(leading: Button("Back") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Year Picker

private struct YearPicker: View {
    let years: [String]
    @Binding var selected: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(years, id: \.self) { year in
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selected = year } }) {
                        Text(year)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(selected == year ? Color.blue : Color(.secondarySystemGroupedBackground))
                            .foregroundColor(selected == year ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Summary Cards

private struct SummaryCards: View {
    let income: Double
    let expenses: Double
    let net: Double
    let currencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            SummaryCard(title: "Income",   value: income,        color: .green,
                        icon: "arrow.up.circle.fill",   currencyCode: currencyCode)
            SummaryCard(title: "Expenses", value: abs(expenses), color: .red,
                        icon: "arrow.down.circle.fill", currencyCode: currencyCode)
            SummaryCard(title: "Net",      value: net,           color: net >= 0 ? .blue : .orange,
                        icon: net >= 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                        currencyCode: currencyCode)
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value.currencyFormat(code: currencyCode))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(14)
    }
}

// MARK: - Monthly Chart

private struct MonthlyChart: View {
    let summaries: [MonthSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Monthly Balance", systemImage: "chart.bar.fill")
                .font(.headline)

            Chart {
                ForEach(summaries) { s in
                    BarMark(
                        x: .value("Month", s.shortName),
                        y: .value("Balance", s.net / 100)
                    )
                    .foregroundStyle(s.net >= 0
                        ? Color.blue.gradient
                        : Color.red.gradient)
                    .cornerRadius(5)
                    .annotation(position: s.net >= 0 ? .top : .bottom) {
                        Text(s.net.currencyFormat)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                            .fixedSize()
                    }
                }
                RuleMark(y: .value("Zero", 0))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { val in
                    AxisGridLine()
                    AxisValueLabel {
                        if let d = val.as(Double.self) {
                            Text("\(Int(d))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Category Breakdown

private struct CategoryBreakdown: View {
    let totals: [(category: Transaction.Category, amount: Double)]
    let grandTotal: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Category Breakdown", systemImage: "square.grid.2x2.fill")
                .font(.headline)

            ForEach(totals, id: \.category) { item in
                CategoryRow(category: item.category,
                            amount: item.amount,
                            proportion: grandTotal > 0 ? item.amount / grandTotal : 0)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

private struct CategoryRow: View {
    let category: Transaction.Category
    let amount: Double
    let proportion: Double

    private var color: Color {
        switch category {
        case .income:    return .blue
        case .groceries: return .orange
        case .utilities: return .purple
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: category.imageName)
                    .foregroundColor(color)
                    .frame(width: 22)
                Text(category.name)
                    .font(.subheadline)
                Spacer()
                Text(amount.currencyFormat)
                    .font(.subheadline.bold())
                Text(String(format: "%.0f%%", proportion * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 34, alignment: .trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))
                        .frame(height: 7)
                    Capsule()
                        .fill(color.gradient)
                        .frame(width: geo.size.width * CGFloat(proportion), height: 7)
                        .animation(.easeOut(duration: 0.4), value: proportion)
                }
            }
            .frame(height: 7)
        }
    }
}

// MARK: - Monthly Detail

private struct MonthlyDetail: View {
    let summaries: [MonthSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Monthly Detail", systemImage: "calendar")
                .font(.headline)
                .padding(.bottom, 12)

            ForEach(summaries.reversed()) { summary in
                MonthDetailRow(summary: summary)
                if summary.id != summaries.first?.id {
                    Divider().padding(.leading, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

private struct MonthDetailRow: View {
    let summary: MonthSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(summary.monthName)
                    .font(.subheadline.bold())
                Spacer()
                Text(summary.net.currencyFormat)
                    .font(.subheadline.bold())
                    .foregroundColor(summary.net >= 0 ? .blue : .red)
            }
            HStack(spacing: 16) {
                Label(summary.income.currencyFormat, systemImage: "arrow.up")
                    .font(.caption)
                    .foregroundColor(.green)
                Label(abs(summary.expenses).currencyFormat, systemImage: "arrow.down")
                    .font(.caption)
                    .foregroundColor(.red)
                Spacer()
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Empty State

private struct EmptyReportView: View {
    let year: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No data for \(year)")
                .font(.title3.bold())
            Text("Add transactions to see your spending report here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(48)
    }
}

// MARK: - MonthSummary

struct MonthSummary: Identifiable {
    let id = UUID()
    let month: Int
    let year: Int
    let income: Double
    let expenses: Double

    var net: Double { income + expenses }

    var monthName: String {
        Month.fromNumber(String(month))?.monthName ?? "Month \(month)"
    }

    var shortName: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        var c = DateComponents()
        c.month = month
        c.year  = year
        return f.string(from: Calendar.current.date(from: c) ?? Date())
    }
}

// MARK: - Month enum

enum Month: String {
    case january = "1", february = "2",  march    = "3"
    case april   = "4", may      = "5",  june     = "6"
    case july    = "7", august   = "8",  september = "9"
    case october = "10", november = "11", december = "12"

    var monthName: String {
        switch self {
        case .january:   return "January"
        case .february:  return "February"
        case .march:     return "March"
        case .april:     return "April"
        case .may:       return "May"
        case .june:      return "June"
        case .july:      return "July"
        case .august:    return "August"
        case .september: return "September"
        case .october:   return "October"
        case .november:  return "November"
        case .december:  return "December"
        }
    }

    static func fromNumber(_ number: String) -> Month? { Month(rawValue: number) }
}
