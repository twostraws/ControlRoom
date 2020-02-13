//
//  FilterField.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct FilterField: NSViewRepresentable {

    let prompt: String
    @Binding var text: String

    typealias NSViewType = NSTextField

    func makeCoordinator() -> FilterField.Coordinator {
        return Coordinator(binding: $text)
    }

    func makeNSView(context: NSViewRepresentableContext<FilterField>) -> NSTextField {
        let tf = NSSearchField(string: text)
        tf.placeholderString = prompt
        tf.delegate = context.coordinator
        tf.bezelStyle = .roundedBezel
        tf.focusRingType = .none
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: NSViewRepresentableContext<FilterField>) {
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
