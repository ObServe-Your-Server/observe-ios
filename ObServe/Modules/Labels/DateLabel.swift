//
//  DateLabel.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.07.25.
//

import SwiftUI

struct DateLabel: View {
    var label: String
    var date: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .foregroundColor(Color.gray)
                    .font(.system(size: 12, weight: .medium))
                
                Text(date)
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.easeInOut, value: date)
            }
            Spacer()
        }
    }
}

#Preview {
    DateLabel(label: "LAST RUNTIME", date: "21.03.2025")
        .background(Color.black)
}
