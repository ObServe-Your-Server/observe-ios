//
//  DetailAppBar.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.08.25.
//

import SwiftUI

struct DetailAppBar: View {
    let serverName: String
    @Binding var contentHasScrolled: Bool
    @Binding var selectedInterval: Interval
    var onClose: () -> Void

    enum Interval: CaseIterable {
        case s1, s2, s5, s10
        var label: String {
            switch self {
            case .s1:  return "1S"
            case .s2:  return "2S"
            case .s5:  return "5S"
            case .s10: return "10S"
            }
        }
        var seconds: Double {
            switch self {
            case .s1:  return 1
            case .s2:  return 2
            case .s5:  return 5
            case .s10: return 10
            }
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(serverName.uppercased())
                    .foregroundColor(.white)

                Button {
                    let all = Interval.allCases
                    if let i = all.firstIndex(of: selectedInterval) {
                        selectedInterval = all[(i + 1) % all.count]
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)

                        Text("INTERVALL: \(selectedInterval.label)")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
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

            Button(action: onClose) {
                ZStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.white)
                }
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
        .padding(.bottom, 10)
        .background(Color.black)
        .overlay(
            VStack(spacing: 0) {
                Spacer()
                if contentHasScrolled {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 2)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: contentHasScrolled)
                }
            }
        )
    }
}

#Preview {
    DetailAppBar(
        serverName: "ASUS PN-42",
        contentHasScrolled: .constant(false),
        selectedInterval: .constant(.s1),
        onClose: {}
    )
    .background(Color.black)
}
