import SwiftUI
import UserNotifications
import AppKit
import ApplicationServices

private enum PauseReason: Equatable {
    case idle
    case stremio

    var message: String {
        switch self {
        case .idle: return "Paused, you stepped away"
        case .stremio: return "Paused for Stremio"
        }
    }

    var icon: String {
        switch self {
        case .idle: return "moon.zzz.fill"
        case .stremio: return "play.tv.fill"
        }
    }
}

struct ContentView: View {
    @State private var intervalMinutes = 30
    @State private var remainingSeconds = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var pauseReason: PauseReason?
    @State private var stremioAwaySince: Date?
    @State private var lastActivityDate = Date()
    @State private var monitorsInstalled = false
    @AppStorage("silentMode") private var silentMode = false

    private let idleThreshold: TimeInterval = 180
    private let stremioResumeGrace: TimeInterval = 30
    private let accent = Color(red: 0.4, green: 0.7, blue: 1.0)

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .opacity(0.15)
                .padding(.horizontal, 18)
            controls
        }
        .frame(width: 240)
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
            installActivityMonitorsIfNeeded()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Sip")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white)

            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: "drop.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(accent)
                    .symbolEffect(.bounce, value: isRunning)
            }

            Text(isRunning ? timeString(remainingSeconds) : "\(intervalMinutes) min")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.snappy, value: remainingSeconds)
                .animation(.snappy, value: isRunning)

            statusLine
                .frame(height: 14)
        }
        .padding(.top, 22)
        .padding(.bottom, 16)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var statusLine: some View {
        if let pauseReason {
            Label(pauseReason.message, systemImage: pauseReason.icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .transition(.opacity)
        } else if isRunning {
            Text("Stay hydrated")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .transition(.opacity)
        } else {
            Text("Ready when you are")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .transition(.opacity)
        }
    }

    private var controls: some View {
        VStack(spacing: 14) {
            if !isRunning {
                HStack(spacing: 22) {
                    stepperButton("minus.circle.fill") {
                        intervalMinutes = max(5, intervalMinutes - 5)
                    }
                    stepperButton("plus.circle.fill") {
                        intervalMinutes = min(180, intervalMinutes + 5)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Button(isRunning ? "Stop" : "Start") {
                isRunning ? stop() : start()
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)

            Toggle("Silent mode", isOn: $silentMode)
                .toggleStyle(.switch)
                .font(.system(size: 12))
                .controlSize(.small)
        }
        .padding(18)
        .animation(.snappy, value: isRunning)
    }

    private func stepperButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
        }
        .font(.system(size: 22))
        .foregroundStyle(accent)
        .buttonStyle(.plain)
    }

    func start() {
        remainingSeconds = intervalMinutes * 60
        isRunning = true
        pauseReason = nil
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        pauseReason = nil
    }

    private func tick() {
        let reason = currentPauseReason()
        if reason != pauseReason {
            withAnimation(.easeInOut(duration: 0.2)) {
                pauseReason = reason
            }
        }
        guard pauseReason == nil else { return }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            sendNotification()
            remainingSeconds = intervalMinutes * 60
        }
    }

    private func currentPauseReason() -> PauseReason? {
        let stremioIsFrontmost = NSWorkspace.shared.frontmostApplication?.localizedName == "Stremio"

        if stremioIsFrontmost {
            stremioAwaySince = nil
            return .stremio
        }

        if pauseReason == .stremio {
            let awaySince = stremioAwaySince ?? Date()
            stremioAwaySince = awaySince
            if Date().timeIntervalSince(awaySince) < stremioResumeGrace {
                return .stremio
            }
        }
        stremioAwaySince = nil

        let idleSeconds = Date().timeIntervalSince(lastActivityDate)
        if idleSeconds >= idleThreshold {
            return .idle
        }
        return nil
    }

    private func installActivityMonitorsIfNeeded() {
        guard !monitorsInstalled else { return }
        monitorsInstalled = true

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)

        let activityEvents: NSEvent.EventTypeMask = [
            .mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown,
            .keyDown, .scrollWheel
        ]

        NSEvent.addGlobalMonitorForEvents(matching: activityEvents) { _ in
            lastActivityDate = Date()
        }
        NSEvent.addLocalMonitorForEvents(matching: activityEvents) { event in
            lastActivityDate = Date()
            return event
        }
    }

    func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Sip 💧"
        content.body = "Time to drink some water"
        content.sound = silentMode ? nil : .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    ContentView()
}
