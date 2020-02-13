//
//  TextView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// A wrapper around NSTextView so we can get multiline text editing in SwiftUI.
struct TextView: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView()
        view.backgroundColor = .textBackgroundColor
        view.delegate = context.coordinator
        view.isRichText = false
        view.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        view.autoresizingMask = [.width, .height]
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    func updateNSView(_ view: NSTextView, context: Context) {
        view.string = text

        guard context.coordinator.selectedRanges.count > 0 else {
            return
        }

        view.selectedRanges = context.coordinator.selectedRanges
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextView
        var selectedRanges = [NSValue]()

        init(_ parent: TextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
            self.selectedRanges = textView.selectedRanges
        }
    }
}
