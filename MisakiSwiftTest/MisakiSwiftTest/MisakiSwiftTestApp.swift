//
//  MisakiSwiftTestApp.swift
//  MisakiSwiftTest
//
//  Created by Lassi Maksimainen on 10.8.2025.
//

import SwiftUI

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil)
    -> Bool
  {
    print("App starting")
    let g2p = EnglishG2P(british: true)
    // let _  = g2p.phonemize(text: "[Misaki](/misˈɑki/) is a G2P engine    designed for [Kokoro](/kˈOkəɹO/) models.")
    let _  = g2p.phonemize(text: "This costs 100€ – and it is not cheap.")
    return true
  }
}

@main
struct MisakiSwiftTestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
