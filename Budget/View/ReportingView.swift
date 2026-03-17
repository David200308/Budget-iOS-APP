//
//  ReportingView.swift
//  Budget
//
//  Created by David Jiang on 15/12/2023.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import SwiftUI
import Charts

// MARK: - Tab

enum ReportTab: String, CaseIterable {
    case day   = "Day"
    case month = "Month"
    case year  = "Year"
}

// MARK: - Root

struct ReportingView: View {
    @EnvironmentObject private var stateController: StateController
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedTab: ReportTab = .year
    @State private var selectedYear: String   = String(Calendar.current.component(.year, from: Date()))
    @State private var selectedMonth: Date    = {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    }()
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())

    private var transactions: [Transaction] {
        stateController.account.transactions.filter { $0.status == 1 }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Period", selection: $selectedTab) {
                        ForEach(ReportTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedTab == .day {
                        DayReportView(
                            selectedDay:  $selectedDay,
                            transactions: transactions,
                            currencyCode: settings.currencyCode,
                            timezone:     settings.timezone
                        )
                    } else if selectedTab == .month {
                        MonthReportView(
                            selectedMonth: $selectedMonth,
                            transactions:  transactions,
                            currencyCode:  settings.currencyCode
                        )
                    } else {
                        YearReportView(
                            selectedYear: $selectedYear,
                            transactions: transactions,
                            currencyCode: settings.currencyCode
                        )
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

// MARK: - Period Navigator

private struct PeriodNavigator: View {
    let label: String
    let onPrev: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .font(.subheadline.bold())
            }
            Spacer()
            Text(label)
                .font(.subheadline.bold())
            Spacer()
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.subheadline.bold())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Day Report

private struct DayReportView: View {
    @Binding var selectedDay: Date
    let transactions: [Transaction]
    let currencyCode: String
    let timezone: TimeZone

    private static let cal = Calendar.current

    private var dayTransactions: [Transaction] {
        transactions
            .filter { Self.cal.isDate($0.date, inSameDayAs: selectedDay) }
            .sorted { $0.date > $1.date }
    }

    private var income:   Double { dayTransactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount } }
    private var expenses: Double { dayTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount } }
    private var net:      Double { income + expenses }

    private var dayLabel: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: selectedDay)
    }

    var body: some View {
        VStack(spacing: 16) {
            PeriodNavigator(label: dayLabel) {
                selectedDay = Self.cal.date(byAdding: .day, value: -1, to: selectedDay) ?? selectedDay
            } onNext: {
                selectedDay = Self.cal.date(byAdding: .day, value: 1, to: selectedDay) ?? selectedDay
            }

            if dayTransactions.isEmpty {
                EmptyReportView(label: dayLabel)
            } else {
                SummaryCards(income: income, expenses: expenses, net: net, currencyCode: currencyCode)

                VStack(alignment: .leading, spacing: 0) {
                    Label("Transactions", systemImage: "list.bullet")
                        .font(.headline)
                        .padding(.bottom, 12)

                    ForEach(Array(dayTransactions.enumerated()), id: \.element.id) { idx, t in
                        DayTransactionRow(transaction: t, currencyCode: currencyCode)
                        if idx < dayTransactions.count - 1 {
                            Divider().padding(.leading, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
        }
    }
}

private struct DayTransactionRow: View {
    let transaction: Transaction
    let currencyCode: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.category.name)
                    .font(.subheadline.bold())
                if !transaction.description.isEmpty {
                    Text(transaction.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(transaction.amount.currencyFormat(code: currencyCode))
                .font(.subheadline.bold())
                .foregroundColor(transaction.amount > 0 ? .blue : .primary)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Month Report

private struct MonthReportView: View {
    @Binding var selectedMonth: Date
    let transactions: [Transaction]
    let currencyCode: String

    private static let cal = Calendar.current

    private var monthTransactions: [Transaction] {
        transactions.filter {
            Self.cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) &&
            Self.cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .year)
        }
    }

    private var income:   Double { monthTransactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount } }
    private var expenses: Double { monthTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount } }
    private var net:      Double { income + expenses }

    private var categoryTotals: [(category: Transaction.Category, amount: Double)] {
        var dict: [Transaction.Category: Double] = [:]
        for t in monthTransactions { dict[t.category, default: 0] += abs(t.amount) }
        let grandTotal = dict.values.reduce(0, +)
        guard grandTotal > 0 else { return [] }
        return Transaction.Category.allCases
            .compactMap { cat in dict[cat].map { (cat, $0) } }
            .sorted { $0.amount > $1.amount }
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedMonth)
    }

    var body: some View {
        VStack(spacing: 16) {
            PeriodNavigator(label: monthLabel) {
                selectedMonth = Self.cal.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
            } onNext: {
                selectedMonth = Self.cal.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
            }

            if monthTransactions.isEmpty {
                EmptyReportView(label: monthLabel)
            } else {
                SummaryCards(income: income, expenses: expenses, net: net, currencyCode: currencyCode)

                if !categoryTotals.isEmpty {
                    let grandTotal = categoryTotals.reduce(0) { $0 + $1.amount }
                    CategoryBreakdown(totals: categoryTotals, grandTotal: grandTotal)
                }
            }
        }
    }
}

// MARK: - Year Report

private struct YearReportView: View {
    @Binding var selectedYear: String
    let transactions: [Transaction]
    let currencyCode: String

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

    private var income:   Double { filtered.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount } }
    private var expenses: Double { filtered.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount } }
    private var net:      Double { income + expenses }

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
        VStack(spacing: 16) {
            if availableYears.count > 1 {
                YearPicker(years: availableYears, selected: $selectedYear)
            }

            if filtered.isEmpty {
                EmptyReportView(label: selectedYear)
            } else {
                SummaryCards(income: income, expenses: expenses, net: net, currencyCode: currencyCode)

                MonthlyChart(summaries: monthlySummaries)

                if !categoryTotals.isEmpty {
                    let grandTotal = categoryTotals.reduce(0) { $0 + $1.amount }
                    CategoryBreakdown(totals: categoryTotals, grandTotal: grandTotal)
                }

                MonthlyDetail(summaries: monthlySummaries)
            }
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
    let label: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No data for \(label)")
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
    case january = "1", february = "2",  march     = "3"
    case april   = "4", may      = "5",  june      = "6"
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
