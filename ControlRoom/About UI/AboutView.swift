//
//  AboutView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/19/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct AboutView: View {
    var appName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "Control Room"
    }

    var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }

    var appBuild: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1.0"
    }

    var copyright: String {
        let copyright = Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        return copyright ?? "Copyright © 2021 Paul Hudson. All rights reserved."
    }

    let authors: [Author]

    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSImage(named: NSImage.applicationIconName)!)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .frame(width: 64, height: 64)

            Text("Control Room")
                .fontWeight(.bold)

            Text("Version \(appVersion) (\(appBuild))")
                .font(.caption)

            if authors.isNotEmpty {
                Text("Built thanks to the contributions of:")
                    .font(.caption)

                // contributors
                CollectionView(authors, horizontalSpacing: 0, horizontalAlignment: .center, verticalSpacing: 0) { author in
                    Button("@\(author.login)") {
                        revealAuthor(author)
                    }
                    .buttonStyle(RecessedButtonStyle())
                }
                .font(.caption)
            }

            Text(copyright)
                .font(.caption)
        }.padding(20)
    }

    func revealAuthor(_ author: Author) {
        NSWorkspace.shared.open(author.htmlUrl)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(authors: [])
    }
}
