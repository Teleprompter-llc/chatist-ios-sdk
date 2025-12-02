//
//  Example_SwiftUIApp.swift
//  Example-SwiftUI
//
//  Created by Kornel Varga on 2025. 12. 02..
//

import ChatistSdk
import SwiftUI

// MARK: - App

@main
struct Example_SwiftUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task {
                    await Chatist.refreshUnreadMessagesCount()
                }
            }
        }
    }
}
