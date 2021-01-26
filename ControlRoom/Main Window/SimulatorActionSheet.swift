//
//  SimulatorActionSheet.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/15/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct SimulatorActionSheet<Content: View>: View {
    @Environment(\.presentationMode) var presentationMode

    let icon: NSImage
    let message: String
    let informativeText: String
    let content: Content

    let confirmationTitle: String
    let confirmationAction: () -> Void
    let canConfirm: Bool

    internal init(icon: NSImage,
                  message: String,
                  informativeText: String,
                  confirmationTitle: String,
                  confirm: @escaping () -> Void,
                  canConfirm: Bool = true,
                  @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.message = message
        self.informativeText = informativeText
        self.content = content()
        self.canConfirm = canConfirm
        self.confirmationTitle = confirmationTitle
        self.confirmationAction = confirm
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(icon.size, contentMode: .fit)
                    .frame(width: 48)

                VStack(alignment: .leading) {
                    Text(message)
                        .fontWeight(.bold)
                        .lineLimit(1)

                    Text(informativeText)
                        .font(.caption)
                        .multilineTextAlignment(.leading)

                    content
                }
            }

            HStack {
                Button("Cancel", action: dismiss)
                Spacer()
                Button(confirmationTitle) {
                    confirmationAction()
                    dismiss()
                }
                .disabled(canConfirm == false)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(minWidth: 300, idealWidth: 400)
        .padding(20)
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

extension SimulatorActionSheet where Content == EmptyView {
    internal init(icon: NSImage,
                  message: String,
                  informativeText: String,
                  confirmationTitle: String,
                  confirm: @escaping () -> Void) {

        self.init(icon: icon, message: message, informativeText: informativeText, confirmationTitle: confirmationTitle, confirm: confirm, content: { EmptyView() })
    }
}
