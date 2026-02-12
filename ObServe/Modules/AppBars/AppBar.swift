//
//  AppBar.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.07.25.
//

import SwiftUI

struct AppBar: View {
    var machineCount: Int
    @Binding var contentHasScrolled: Bool
    @Binding var showBurgerMenu: Bool
    @Binding var selectedSortType: SortType

    enum SortType: String, CaseIterable {
        case all = "ALL"
        case online = "ON"
        case offline = "OFF"
    }

    var body: some View {
        BaseAppBar(
            title: "\(machineCount) \(machineCount == 1 ? "MACHINE" : "MACHINES")",
            contentHasScrolled: $contentHasScrolled,
            rightButtonType: .hamburgerMenu,
            rightButtonAction: { showBurgerMenu = true }
        ) {
            Button(action: {
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
    }
}

#Preview {
    AppBar(
        machineCount: 3,
        contentHasScrolled: .constant(false),
        showBurgerMenu: .constant(false),
        selectedSortType: .constant(.all)
    )
    .background(Color.black)
}
