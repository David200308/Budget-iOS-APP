//
//  ReportingView.swift
//  Budget
//
//  Created by David Jiang on 15/12/2023.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import SwiftUI
import Charts
import UniformTypeIdentifiers

struct ReportingView: View {
    @State private var year: String = ""
    @State private var month: String = ""
    @State private var amount: String = ""
    
    @EnvironmentObject private var stateController: StateController
    @Environment(\.presentationMode) private var presentationMode
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        NavigationView {
            ReportContent(year: $year, month: $month, amount: $amount, statistics: readStatisticData())
                .navigationBarTitle("Statistic Report")
                .navigationBarItems(leading: Button(action: { self.dismiss() }) {
                    Text("Back")
                    })
        }
    }
    
}

enum Month: String {
    case january = "1"
    case february = "2"
    case march = "3"
    case april = "4"
    case may = "5"
    case june = "6"
    case july = "7"
    case august = "8"
    case september = "9"
    case october = "10"
    case november = "11"
    case december = "12"
    
    var monthName: String {
        switch self {
        case .january:
            return "January"
        case .february:
            return "February"
        case .march:
            return "March"
        case .april:
            return "April"
        case .may:
            return "May"
        case .june:
            return "June"
        case .july:
            return "July"
        case .august:
            return "August"
        case .september:
            return "September"
        case .october:
            return "October"
        case .november:
            return "November"
        case .december:
            return "December"
        }
    }
    
    static func fromNumber(_ number: String) -> Month? {
        return Month(rawValue: number)
    }
}

struct ReportContent: View {
    @Binding var year: String
    @Binding var month: String
    @Binding var amount: String
    var statistics: [Statistic]

    @available(iOS 16.0, *)
    var body: some View {
        VStack {
            GroupBox("Monthly Expense") {
                Chart {
                    ForEach(statistics.filter({ $0.month != "All" })) { data in
                        BarMark(
                            x: .value("Month", data.year + " - " + data.month),
                            y: .value("Expense", data.amount / (-100)),
                            width: .fixed(20)
                        )
                    }
                }
            }
            .padding()
        }

        List {
            ForEach(statistics) { stat in
                if stat.month == "All" {
                    HStack {
                        Text("Year \(stat.year)").bold().font(.title3)
                        Text("Balance: " + String(format: "%.2f", stat.amount / 100))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.title3)
                    }
                } else {
                    let tempMonth = Month.fromNumber(stat.month)!.monthName
                    HStack {
                        Text(tempMonth).bold().font(.headline)
                        Text(String(format: "%.2f", stat.amount / 100))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}
