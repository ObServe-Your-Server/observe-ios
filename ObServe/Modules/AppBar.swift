//
//  AppBar.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.07.25.
//

import SwiftUI

struct AppBar: View {
    var machineCount: Int
    @Binding var selectedSortType: SortType
    
    enum SortType: String, CaseIterable {
        case all = "ALL"
        case online = "ON"
        case offline = "OFF"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(machineCount) \(machineCount == 1 ? "MACHINE" : "MACHINES")")
                Button(action: {
                    // Später Später
                    let allCases = SortType.allCases
                    if let idx = allCases.firstIndex(of: selectedSortType) {
                        let nextIdx = (idx + 1) % allCases.count
                        selectedSortType = allCases[nextIdx]
                    }
                }) {
                    Text("SORT: \(selectedSortType.rawValue)")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color("ButtonBackground"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
            }
            Spacer()
            Button(action: {
                // Später Später
            }) {
                VStack(spacing: 7) {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 24, height: 2.5)
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 24, height: 2.5)
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 24, height: 2.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(10)
                .frame(width: 40, height: 40)
                .background(Color("ButtonBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 5)
        .background(Color.black)
    }
}

#Preview {
    AppBar(machineCount: 0, selectedSortType: .constant(.all))
}
