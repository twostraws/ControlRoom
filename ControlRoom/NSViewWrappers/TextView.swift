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
    @Binding private var text: String
    private let isEditable: Bool

    init(text: Binding<String>, isEditable: Bool = true) {
        _text = text
        self.isEditable = isEditable
    }

    init(text: String) {
        self.init(text: Binding<String>.constant(text), isEditable: false)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let text = NSTextView()
        text.backgroundColor = isEditable ? .textBackgroundColor : .clear
        text.delegate = context.coordinator
        text.isRichText = false
        text.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        text.autoresizingMask = [.width]
        text.translatesAutoresizingMaskIntoConstraints = true
        text.isVerticallyResizable = true
        text.isHorizontallyResizable = false
        text.isEditable = isEditable

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.documentView = text
        scroll.drawsBackground = false

        return scroll
    }

    func updateNSView(_ view: NSScrollView, context: Context) {
        let text = view.documentView as? NSTextView
        text?.string = self.text

        guard context.coordinator.selectedRanges.count > 0 else {
            return
        }

        text?.selectedRanges = context.coordinator.selectedRanges
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
            parent.text = textView.string
            selectedRanges = textView.selectedRanges
        }
    }
}
