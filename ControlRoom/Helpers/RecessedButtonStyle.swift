//
//  RecessedButtonStyle.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/19/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct RecessedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        RecessedButton(isPressed: configuration.isPressed, label: configuration.label)
    }
}

struct RecessedButton<Label: View>: View {
    let isPressed: Bool
    let label: Label

    @State private var isHovering = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var bgColor: Color {
        switch (colorScheme, isHovering, isPressed) {
        case (.dark, false, false): return Color(white: 0.0, opacity: 0.0)
        case (.dark, true, false): return Color(white: 1.0, opacity: 0.25)
        case (.dark, _, true): return Color(white: 1.0, opacity: 0.4)

        case (_, false, false): return Color(white: 0.0, opacity: 0.0)
        case (_, true, false): return Color(white: 0.0, opacity: 0.25)
        case (_, _, true): return Color(white: 0.0, opacity: 0.6)
        }
    }

    var fgColor: Color {
        switch (colorScheme, isHovering) {
        case (.dark, false): return Color(white: 0.75, opacity: 1.0)
        case (.dark, true): return Color(white: 1.0, opacity: 1.0)

        case (_, false): return Color(white: 0.2, opacity: 1.0)
        case (_, true): return Color(white: 1.0, opacity: 1.0)
        }
    }

    var body: some View {
        label
            .padding(EdgeInsets(top: 0, leading: 6, bottom: 1, trailing: 6))
            .foregroundColor(fgColor)
            .background(RoundedRectangle(cornerRadius: 4).fill(bgColor).animation(.none))
            .onHover { isHovering = $0 }
    }
}
