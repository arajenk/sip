//
//  ContentView.swift
//  sip
//
//  Created by Arajen Kajanthirabalan on 2026-09-13.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var intervalMinutes = 30
    @State private var remainingSeconds = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    var body: some View {
        VStack {
            Stepper("Every \(intervalMinutes) min", value: $intervalMinutes, in: 5...180, step: 5)
               
            Button(isRunning ? "Stop" : "Start") {
                if isRunning {
                    stop()
                }
                else{
                    start()
                }
            }
            
        }.onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
    func start(){
        remainingSeconds = intervalMinutes * 60
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            remainingSeconds -= 1
        }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            sendNotification()
            remainingSeconds = intervalMinutes * 60
        }
    }
    func stop(){
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Sip 💧"
        content.body = "Time to drink some water!"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    ContentView()
}
