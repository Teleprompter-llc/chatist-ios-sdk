//
//  ContentView.swift
//  Example-SwiftUI
//
//  Created by Kornel Varga on 2025. 12. 02..
//

import ChatistSdk
import Combine
import SwiftUI

struct ContentView: View {

    // MARK: State

    @State private var unreadCount: Int = 0
    @State private var currentNotification: ChatistNotification?
    @State private var isNotificationVisible: Bool = false

    // MARK: Body

    var body: some View {
        ZStack {
            Color(red: 0.99, green: 0.90, blue: 0.54)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Unread messages: \(unreadCount)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)

                Button("Open Chatist") {
                    Chatist.open()
                }
                .foregroundColor(.black)

                HStack(spacing: 20) {
                    Button("Login") {
                        Chatist.login()
                    }
                    .foregroundColor(.green)

                    Button("Logout") {
                        Chatist.logout()
                    }
                    .foregroundColor(.red)
                }
            }

            if let notification = currentNotification {
                VStack {
                    Spacer()

                    ChatistNotificationViewWrapper(
                        notification: notification,
                        onTap: {
                            // Hide notification and open Chatist with the specific ticket
                            hideNotification()
                            Chatist.open(with: notification.ticketID)
                        },
                        onClose: {
                            hideNotification()
                        }
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 0)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                    .opacity(isNotificationVisible ? 1 : 0)
                    .offset(y: isNotificationVisible ? 0 : 20)
                }
            }
        }
        // Subscribe to unread messages count updates
        .onReceive(
            Chatist.getUnreadMessagesCount()
                .receive(on: DispatchQueue.main)
        ) { count in
            unreadCount = count
        }
        // Subscribe to notification events
        .onReceive(
            Chatist.observeNotifications()
                .receive(on: DispatchQueue.main)
        ) { notification in
            showNotification(notification)
        }
    }
}

// MARK: - Functions

extension ContentView {
    private func showNotification(_ notification: ChatistNotification) {
        if currentNotification != nil {
            hideNotification()
        }

        currentNotification = notification

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
            isNotificationVisible = true
        }
    }

    private func hideNotification() {
        withAnimation(.easeOut(duration: 0.2)) {
            isNotificationVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentNotification = nil
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
