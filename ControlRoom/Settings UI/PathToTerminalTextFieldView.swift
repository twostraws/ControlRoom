//
//  PathToTerminalTextFieldView.swift
//  ControlRoom
//
//  Created by Elliot Knight on 11/05/2024.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//

import SwiftUI

struct PathToTerminalTextFieldView: View {
    @EnvironmentObject var preferences: Preferences

    var body: some View {
        Form {
            TextField(
                "Path to Terminal",
                text: $preferences.terminalAppPath
            )
            .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    PathToTerminalTextFieldView()
        .environmentObject(Preferences())
}
