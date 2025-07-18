//
//  AddServerModule.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.07.25.
//

import SwiftUI

struct AddServerModule: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Add New Machine")
                .font(.title)
                .foregroundColor(.white)
            // Placeholder for form fields
            Spacer()
        }
        .padding()
        .background(Color.black)
    }
}

#Preview {
    AddServerModule()
}
