//
//  AboutObServeView.swift
//  ObServe
//
//  Created by Daniel Schatz
//

import SwiftUI

struct AboutObServeView: View {
    @State private var contentHasScrolled = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            AppBar(
                title: "ABOUT ObServe",
                contentHasScrolled: $contentHasScrolled,
                onClose: { dismiss() },
                secondaryIcon: "arrow.up.right",
                secondaryLabel: "WEBSITE",
                secondaryAction: {
                    if let url = URL(string: "https://observe.vision") {
                        UIApplication.shared.open(url)
                    }
                }
            )

            ScrollView {
                ScrollDetector(contentHasScrolled: $contentHasScrolled)

                VStack(spacing: 18) {
                    sectionHeader("THE DEVELOPERS")
                    HStack(alignment: .top) {
                            Text("""
                                Daniel blickt auf Carlos Werke,
                                sein Blick so scharf wie eine Klinge.
                                In seiner Brust lodert ein Feuer,
                                geboren aus Neid, gewürzt mit Zorn.
                                
                                Sein Optiplex schnurrt wie eine alte Katze, 
                                sein MacBook Air flüstert schwach im Wind.
                                Doch Carlos schmiedet Welten in Figma,
                                während Daniel nur die Tasten zählt.
                                
                                Und so sitzt er,
                                gefangen zwischen Ehrgeiz und Eifersucht,
                                wissend, dass er mit diesem Werkzeug
                                niemals den Himmel berühren wird.
                                """)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                                .frame(maxWidth: .infinity)
                                .frame(maxWidth: UIScreen.main.bounds.width / 6)
                        }
                    
                    sectionHeader("CONTACT")

                    Text("MAIL: support@observe.vision")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tint(.gray)
                        

                    Rectangle().fill(.clear).frame(height: 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            }
            .coordinateSpace(name: "scroll")
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Kleine Helfer
    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.white)
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 1)
        }
    }
}

#Preview {
    AboutObServeView()
}
