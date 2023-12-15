//
//  ReportingView.swift
//  Budget
//
//  Created by David Jiang on 15/12/2023.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import SwiftUI
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

struct ReportContent: View {
    @Binding var year: String
    @Binding var month: String
    @Binding var amount: String
    var statistics: [Statistic]

    var body: some View {
        List {
            ForEach(statistics) { stat in
                HStack {
                    Text("\(stat.year) - \(stat.month)").bold().font(.title3)
                    Text("Balance: " + String(format: "%.2f", stat.amount / 100)).frame(maxWidth: .infinity, alignment: .trailing).font(.title3)
                }
            }
        }
    }
}
