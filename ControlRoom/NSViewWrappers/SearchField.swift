//
//  FilterField.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// A wrapper around NSSearchField so we get a macOS-native search box
struct SearchField: NSViewRepresentable {
    /// The text entered by the user.
    @Binding var text: String
    var onClear: () -> Void

    /// Placeholder text for the text field.
    let prompt: String

    init(_ prompt: String, text: Binding<String>, onClear: @escaping () -> Void) {
        self.onClear = onClear
        self.prompt = prompt
        _text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(binding: $text, onClear: onClear)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let textField = NSSearchField(string: text)
        textField.placeholderString = prompt
        textField.delegate = context.coordinator
        textField.bezelStyle = .roundedBezel
        textField.focusRingType = .none
        return textField
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text
    }

    class Coordinator: NSObject, NSSearchFieldDelegate {
        let binding: Binding<String>
        let onClear: () -> Void

        init(binding: Binding<String>, onClear: @escaping () -> Void) {
            self.binding = binding
            self.onClear = onClear
            super.init()
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            binding.wrappedValue = field.stringValue

            if field.stringValue.isEmpty {
                onClear()
            }
        }
    }
}
