//
//  ContentView.swift
//  MisakiSwiftTest
//
//  Created by Lassi Maksimainen on 10.8.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Button {
                print("Pressed")
            } label: {
                Text("Press me")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.black)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
