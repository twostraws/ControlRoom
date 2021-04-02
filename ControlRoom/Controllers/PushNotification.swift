//
//  PushNotification.swift
//  ControlRoom
//
//  Created by Mario Iannotta on 29/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Foundation

struct PushNotification: Codable {
    let aps: PushNotificationAPS
}

struct PushNotificationAPS: Codable {
    private enum CodingKeys: String, CodingKey {
        case alert
        case badge
        case sound
        case threadID = "thread-id"
        case category
        case isContentAvailable = "content-available"
        case isMutableContent = "mutable-content"
        case targetContentID = "target-content-id"
    }

    /**
     The information for displaying an alert.
     */
    var alert = Alert()

    /**
     The number to display in a badge on your app’s icon. Specify 0 to remove the current badge, if any.
     */
    var badge = ""

    /**
     This object takes care of both critical and regular alerts.
     */
    var sound = Sound()

    /**
     An app-specific identifier for grouping related notifications.
     This value corresponds to the `threadIdentifier` property in the `UNNotificationContent` object.
     */
    var threadID = ""

    /**
     The notification’s type. This string must correspond to the identifier of one of the `UNNotificationCategory` objects you register at launch time.
     */
    var category = ""

    /**
     The background notification flag. To perform a silent background update, specify the value true and don't include the alert, badge, or sound keys in your payload.
     */
    var isContentAvailable = false

    /**
     The notification service app extension flag. If the value is true, the system passes the notification to your notification service app extension before delivery.
     Use your extension to modify the notification’s content.
     */
    var isMutableContent = false

    /**
     The identifier of the window brought forward. The value of this key will be populated on the `UNNotificationContent` object created from the push payload.
     Access the value using the `UNNotificationContent` object's `targetContentIdentifier` property.
     */
    var targetContentID = ""

    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        guard
            let data = try? encoder.encode(self),
            let output = String(data: data, encoding: .utf8)
            else {
                return ""
            }

        return output
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if !isContentAvailable {
            try container.encode(alert, forKey: .alert)
            try container.encode(sound, forKey: .sound)
            let numericBadge = Int(badge) ?? -1
            if numericBadge > -1 {
                try container.encode(numericBadge, forKey: .badge)
            }
        } else {
            try container.encode(1, forKey: .isContentAvailable)
        }

        try container.encodeIfNotEmpty(threadID, forKey: .threadID)
        try container.encodeIfNotEmpty(category, forKey: .category)

        if isMutableContent {
            try container.encode(1, forKey: .isMutableContent)
        }

        try container.encodeIfNotEmpty(targetContentID, forKey: .targetContentID)
    }

    init() { }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isContentAvailable = (try container.decodeIfPresent(Int.self, forKey: .isContentAvailable) == 1 ? true : false)

        if !isContentAvailable {
            alert = try container.decodeIfPresent(Alert.self, forKey: .alert) ?? Alert()
            sound = try container.decodeIfPresent(Sound.self, forKey: .sound) ?? Sound()

            if let badgeValue = try container.decodeIfPresent(Int.self, forKey: .badge) {
                badge = String(badgeValue)
            }
        }

        threadID = try container.decodeIfPresent(String.self, forKey: .threadID) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        isMutableContent = (try container.decodeIfPresent(Int.self, forKey: .isMutableContent) == 1 ? true : false)
        targetContentID = try container.decodeIfPresent(String.self, forKey: .targetContentID) ?? ""
    }
}

// swiftlint:disable nesting
extension PushNotificationAPS {
    struct Alert: Codable {
        private enum CodingKeys: String, CodingKey {
            case title
            case subtitle
            case body
            case launchImage = "launch-image"
            case titleLocKey = "title-loc-key"
            case titleLocArgs = "title-loc-args"
            case subtitleLocKey = "subtitle-loc-key"
            case subtitleLocArgs = "subtitle-loc-args"
            case locKey = "loc-key"
            case locArgs = "loc-args"
        }
        /**
         If true, `titleLocKey` and `titleLocArgs` will be used instead of` title`, `subtitleLocKey` and `subtitleLocArgs` instead of `subtitle` and  `locKey` and `locArgs` instead of `body`.
         */
        var isLocalizedContentAvailable: Bool {
            titleLocKey.count + titleLocArgs.count + subtitleLocKey.count + subtitleLocArgs.count + locKey.count + locArgs.count > 0
        }

        /**
         The title of the notification. Apple Watch displays this string in the short look notification interface. Specify a string that is quickly understood by the user.
         */
        var title = ""

        /**
         Additional information that explains the purpose of the notification.
         */
        var subtitle = ""

        /**
         The content of the alert message.
         */
        var body = ""

        /**
         The name of the launch image file to display. If the user chooses to launch your app,
         the contents of the specified image or storyboard file are displayed instead of your app's normal launch image.
         */
        var launchImage = ""

        /**
         The key for a localized title string. Specify this key instead of the title key to retrieve the title from your app’s Localizable.strings files.
         The value must contain the name of a key in your strings file.
         */
        var titleLocKey = ""

        /**
         An array of strings containing replacement values for variables in your title string.
         Each %@ character in the string specified by the titleLocalizedKey is replaced by a value from this array.
         The first item in the array replaces the first instance of the %@ character in the string, the second item replaces the second instance, and so on.
         */
        var titleLocArgs = ""

        /**
         The key for a localized subtitle string. Use this key, instead of the subtitle key, to retrieve the subtitle from your app's Localizable.strings file.
         The value must contain the name of a key in your strings file.
         */
        var subtitleLocKey = ""

        /**
         An array of strings containing replacement values for variables in your subtitle string.
         Each %@ character in the string specified by subtitle-loc-key is replaced by a value from this array.
         The first item in the array replaces the first instance of the %@ character in the string, the second item replaces the second instance, and so on.
         */
        var subtitleLocArgs = ""

        /**
         The key for a localized message string. Use this key, instead of the body key, to retrieve the message text from your app's Localizable.strings file.
         The value must contain the name of a key in your strings file.
         */
        var locKey = ""

        /**
         An array of strings containing replacement values for variables in your message text.
         Each %@ character in the string specified by loc-key is replaced by a value from this array.
         The first item in the array replaces the first instance of the %@ character in the string, the second item replaces the second instance, and so on.
         */
        var locArgs = ""

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if isLocalizedContentAvailable {
                try container.encodeIfNotEmpty(titleLocKey, forKey: .titleLocKey)
                try container.encodeIfNotEmpty(subtitleLocKey, forKey: .subtitleLocKey)
                try container.encodeIfNotEmpty(locKey, forKey: .locKey)
                try container.encodeIfNotEmpty(titleLocArgs.toComponents(), forKey: .titleLocArgs)
                try container.encodeIfNotEmpty(subtitleLocArgs.toComponents(), forKey: .subtitleLocArgs)
                try container.encodeIfNotEmpty(locArgs.toComponents(), forKey: .locArgs)
            } else {
                try container.encodeIfNotEmpty(title, forKey: .title)
                try container.encodeIfNotEmpty(subtitle, forKey: .subtitle)
                try container.encodeIfNotEmpty(body, forKey: .body)
            }

            try container.encodeIfNotEmpty(launchImage, forKey: .launchImage)
        }

        init() { }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
            subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
            body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
            launchImage = try container.decodeIfPresent(String.self, forKey: .launchImage) ?? ""
            titleLocKey = try container.decodeIfPresent(String.self, forKey: .titleLocKey) ?? ""
            subtitleLocKey = try container.decodeIfPresent(String.self, forKey: .subtitleLocKey) ?? ""
            locKey = try container.decodeIfPresent(String.self, forKey: .locKey) ?? ""
            titleLocArgs = (try container.decodeIfPresent([String].self, forKey: .titleLocArgs) ?? []).joined(separator: ", ")
            subtitleLocArgs = (try container.decodeIfPresent([String].self, forKey: .subtitleLocArgs) ?? []).joined(separator: ", ")
            locArgs = (try container.decodeIfPresent([String].self, forKey: .locArgs) ?? []).joined(separator: ", ")
        }
    }
}

extension PushNotificationAPS {
    struct Sound: Codable {
        private enum CodingKeys: String, CodingKey {
            case isCritical = "critical"
            case name
            case volume
        }

        /**
         The critical alert flag. Set to true to enable the critical alert.
         */
        var isCritical = false

        /**
         The name of a sound file in your app’s main bundle or in the Library/Sounds folder of your app’s container directory.
         Specify the string "default" to play the system sound. For information about how to prepare sounds, see `UNNotificationSound`.
         */
        var name = "default"

        /**
         The volume for the critical alert’s sound. Set this to a value between 0.0 (silent) and 1.0 (full volume).
         */
        var volume: Double = 0

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfNotEmpty(name, forKey: .name)
            if isCritical {
                try container.encode(1, forKey: .isCritical)
                try container.encode(String(format: "%.2f", volume), forKey: .volume)
            }
        }

        init() { }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            isCritical = (try container.decodeIfPresent(Int.self, forKey: .isCritical)) == 1 ? true : false
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""

            if isCritical {
                volume = Double(try container.decodeIfPresent(String.self, forKey: .volume) ?? "") ?? 0
            }
        }
    }
}
// swiftlint:enable nesting

private extension String {
    func toComponents() -> [String] {
        components(separatedBy: ",").compactMap { component in
            let component = component.trimmingCharacters(in: .whitespaces)
            return component.isEmpty ? nil : component
        }
    }
}
