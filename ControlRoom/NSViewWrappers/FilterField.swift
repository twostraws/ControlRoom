//
//  FilterField.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// A wrapper around NSSearchField so we get a macOS-native search box
struct FilterField: NSViewRepresentable {
    /// The text entered by the user.
    @Binding var text: String

    /// Placeholder text for the text field.
    let prompt: String

    init(_ prompt: String, text: Binding<String>) {
        self.prompt = prompt
        _text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(binding: $text)
    }

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSSearchField(string: text)
        tf.placeholderString = prompt
        tf.delegate = context.coordinator
        tf.bezelStyle = .roundedBezel
        tf.focusRingType = .none
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }

    class Coordinator: NSObject, NSSearchFieldDelegate {
        let binding: Binding<String>

        init(binding: Binding<String>) {
            self.binding = binding
            super.init()
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            binding.wrappedValue = field.stringValue
        }
    }
}
