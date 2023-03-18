//
//  CategoryView.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import SwiftUI

struct CategoryView: View {
	let category: Transaction.Category
	var highlighted: Bool = true
	
    var body: some View {
		ZStack {
			Circle()
				.frame(width: 56.0, height: 56.0)
				.foregroundColor(highlighted ? Color(.systemTeal) : Color(.quaternarySystemFill))
			Image(systemName: category.imageName)
				.font(.headline)
				.foregroundColor(highlighted ? .white : .primary)
		}
    }
}

struct CategoryView_Previews: PreviewProvider {
    static var previews: some View {
		HStack {
			ForEach(Transaction.Category.allCases, id: \.rawValue) { category in
				VStack {
					CategoryView(category: category)
					CategoryView(category: category, highlighted: false)
				}
			}
		}.previewLayout(.sizeThatFits)
    }
}
