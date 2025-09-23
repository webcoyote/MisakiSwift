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
              let fallback = EnglishFallbackNetwork(british: false)
              let str = "Kokoro"
              let range: Range<String.Index> = Range(uncheckedBounds: (lower: str.startIndex, upper: str.endIndex))
              let output = fallback(MToken(text: str, tokenRange: range, whitespace: " "))
              print(output)
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
