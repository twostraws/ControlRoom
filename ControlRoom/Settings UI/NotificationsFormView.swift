//
//  NotificationsFormView.swift
//  ControlRoom
//
//  Created by Elliot Knight on 11/05/2024.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//

import SwiftUI
import KeyboardShortcuts

struct NotificationsFormView: View {
    var body: some View {
        Form {
            makeKeyboardShortcut(title: "Resend last push notification", for: .resendLastPushNotification)
            makeKeyboardShortcut(title: "Restart last selected app", for: .restartLastSelectedApp)
            makeKeyboardShortcut(title: "Reopen last URL", for: .reopenLastURL)
        }
    }

    private func makeKeyboardShortcut(title: String, for name: KeyboardShortcuts.Name) -> some View {
        HStack {
            Text(title)
            KeyboardShortcuts.Recorder(for: name)
        }
    }
}

#Preview {
    NotificationsFormView()
}
