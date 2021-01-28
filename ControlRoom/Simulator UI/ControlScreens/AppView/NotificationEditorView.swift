//
//  NotificationEditorView.swift
//  ControlRoom
//
//  Created by Mario Iannotta on 01/03/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct NotificationEditorView: View {
    @EnvironmentObject var preferences: Preferences
    @State private var notificationAps = PushNotificationAPS()
    @State private var userInfo = ""
    @State private var shouldDismissConfirmationAlert: Bool = false

    private var fullJson: String {
        guard
            let fullJsonString = "{\"aps\":\(notificationAps.json), \(userInfo)}".data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: fullJsonString, options: []),
            let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
            let prettyPrintedJson = String(data: data, encoding: .utf8)
            else {
                return ""
            }
        return prettyPrintedJson
    }

    var body: some View {
        VStack(alignment: .trailing) {
            HStack(spacing: 30) {
                APSFormView(notificationAps: $notificationAps)

                VStack(alignment: .leading) {
                    Text("Aps")
                        .font(.headline)
                        .addingInfoButton(title: "APS", description: "NotificationView.Hints.APS")

                    TextView(text: .constant(notificationAps.json))
                        .font(.system(.body, design: .monospaced))
                        .disableAutocorrection(true)
                        .frame(height: 200)

                    Text("User info")
                        .font(.headline)
                        .addingInfoButton(title: "User info", description: "NotificationView.Hints.UserInfo")

                    TextView(text: $userInfo)
                        .font(.system(.body, design: .monospaced))
                        .disableAutocorrection(true)
                        .frame(height: 200)

                    Spacer()
                }
            }

            HStack(spacing: 10) {
                Button("Discard", action: discardNotificationJson)
                Button("Save", action: saveNotificationJson)
            }
            .alert(isPresented: $shouldDismissConfirmationAlert) {
                Alert(title: Text("Are you sure you want to discard the changes?"),
                      message: Text("You can’t undo this action."),
                      primaryButton: .destructive(Text("Discard changes"), action: dismiss),
                      secondaryButton: .default(Text("Cancel")))
            }
        }
        .padding(20)
        .onAppear {
            notificationAps = preferences.pushPayload
                .data(using: .utf8)
                .flatMap { try? JSONDecoder().decode(PushNotification.self, from: $0) }?.aps ?? PushNotificationAPS()
            }
        .frame(minWidth: 850, minHeight: 720)
    }

    private func saveNotificationJson() {
        preferences.pushPayload = fullJson
        dismiss()
    }

    private func discardNotificationJson() {
        if preferences.pushPayload != fullJson {
            shouldDismissConfirmationAlert = true
        } else {
            dismiss()
        }
    }

    private func dismiss() {
        UIState.shared.currentSheet = .none
    }

    private func copyFullJsonToClipboard() {
        NSPasteboard.general.setString(fullJson, forType: .string)
    }
}

private struct APSFormView: View {
    @Binding private var notificationAps: PushNotificationAPS

    @State private var selectedTabIndex = 1

    init(notificationAps: Binding<PushNotificationAPS>) {
        _notificationAps = notificationAps
        self.selectedTabIndex = self.notificationAps.alert.isLocalizedContentAvailable ? 2 : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 15) {
                Text("Alert")
                    .font(.headline)
                TabView(selection: $selectedTabIndex) {
                    Group {
                        VStack(spacing: 10) {
                            FieldView(title: "Title",
                                      description: "NotificationView.Hints.Alert.Title",
                                      value: $notificationAps.alert.title)
                            FieldView(title: "Subtitle",
                                      description: "NotificationView.Hints.Alert.Subtitle",
                                      value: $notificationAps.alert.subtitle)
                            FieldView(title: "Body",
                                      description: "NotificationView.Hints.Alert.Body",
                                      value: $notificationAps.alert.body)
                        }
                        .tabItem {
                            Text("Regular")
                        }
                        .tag(1)

                        VStack(spacing: 10) {
                            LocalizedFieldView(title: "Title",
                                               value: $notificationAps.alert.titleLocKey,
                                               arguments: $notificationAps.alert.titleLocArgs,
                                               valueDescription: "NotificationView.Hints.Alert.TitleLocKey",
                                               argumentsDescription: "NotificationView.Hints.Alert.TitleLocArgs")
                            LocalizedFieldView(title: "Subtitle",
                                               value: $notificationAps.alert.subtitleLocKey,
                                               arguments: $notificationAps.alert.subtitleLocArgs,
                                               valueDescription: "NotificationView.Hints.Alert.SubtitleLocKey",
                                               argumentsDescription: "NotificationView.Hints.Alert.SubtitleLocArgs")
                            LocalizedFieldView(title: "Body",
                                               value: $notificationAps.alert.locKey,
                                               arguments: $notificationAps.alert.locArgs,
                                               valueDescription: "NotificationView.Hints.Alert.BodyLocKey",
                                               argumentsDescription: "NotificationView.Hints.Alert.BodyLocArgs")
                        }
                        .tabItem {
                            Text("Localized")
                        }
                        .tag(2)
                    }
                    .padding(20)
                }
                .frame(height: 210)
            }

            VStack(alignment: .leading, spacing: 20) {
                Text("Sound")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    FieldView(title: "File name",
                              description: "NotificationView.Hints.Sound.Name",
                              value: $notificationAps.sound.name)

                    HStack {
                        ToggleFieldView(title: "Critical",
                                        description: "NotificationView.Hints.Sound.Critical",
                                        value: $notificationAps.sound.isCritical)
                        SliderFieldView(title: "Volume",
                                        description: "NotificationView.Hints.Sound.Volume",
                                        value: $notificationAps.sound.volume,
                                        isEnabled: notificationAps.sound.isCritical)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 20) {
                Text("Misc")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        FieldView(title: "Badge",
                                  description: "NotificationView.Hints.Badge",
                                  value: $notificationAps.badge)
                        FieldView(title: "Launch image name",
                                  description: "NotificationView.Hints.LaunchImage",
                                  value: $notificationAps.alert.launchImage)
                    }

                    HStack(spacing: 10) {
                        FieldView(title: "Thread identifier",
                                  description: "NotificationView.Hints.ThreadIdentifier",
                                  value: $notificationAps.threadID)
                        FieldView(title: "Category",
                                  description: "NotificationView.Hints.Category",
                                  value: $notificationAps.category)
                    }

                    HStack(spacing: 30) {
                        ToggleFieldView(title: "Silent",
                                        description: "NotificationView.Hints.SilentNotification",
                                        value: $notificationAps.isContentAvailable)
                        ToggleFieldView(title: "Rich push",
                                        description: "NotificationView.Hints.MutableContent",
                                        value: $notificationAps.isMutableContent)
                    }

                    FieldView(title: "Target content identifier",
                              description: "NotificationView.Hints.TargetContentIdentifier",
                              value: $notificationAps.targetContentID)
                }
            }

            Spacer()
        }
    }
}

private struct LocalizedFieldView: View {
    let title: String

    @Binding var value: String
    @Binding var arguments: String

    let valueDescription: String
    let argumentsDescription: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)

            HStack(spacing: 10) {
                TextField("Localized key", text: $value)
                    .addingInfoButton(title: "Localized key", description: valueDescription)

                TextField("Localized arguments", text: $arguments)
                    .addingInfoButton(title: "Localized key", description: argumentsDescription)
            }
        }
    }
}

private struct FieldView: View {
    let title: String
    let description: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)

            TextField(title, text: $value)
                .addingInfoButton(title: title, description: description)
        }
    }
}

private struct ToggleFieldView: View {
    let title: String
    let description: String
    @Binding var value: Bool

    var body: some View {
        HStack {
            Toggle(isOn: $value, label: { Text(title) })
        }
        .addingInfoButton(title: title, description: description)
    }
}

private struct SliderFieldView: View {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        return  formatter
    }()

    let title: String
    let description: String
    @Binding var value: Double
    let isEnabled: Bool

    var body: some View {
        HStack {
            Slider(value: $value, label: { Text(title) })
            Text(sliderDisplayValue)
        }
        .disabled(!isEnabled)
        .addingInfoButton(title: title, description: description)
    }

    var sliderDisplayValue: String {
        Self.numberFormatter.string(for: value) ?? ""
    }
}

private extension View {
    func addingInfoButton(title: String, description: String) -> some View {
        modifier(InfoButtonModifier(title: title,
                                    description: description.localizedHint))
    }
}

private struct InfoButtonModifier: ViewModifier {
    let title: String
    let description: String

    @State private var shouldShowDescription = false

    func body(content: Content) -> some View {
        HStack {
            content

            Button("?") {
                shouldShowDescription = true
            }
        }
        .alert(isPresented: $shouldShowDescription) {
            Alert(title: Text(title), message: Text(description))
        }
    }
}

private extension String {
    var localizedHint: String {
        NSLocalizedString(self, tableName: "NotificationEditorView", bundle: .main, comment: "")
    }
}
