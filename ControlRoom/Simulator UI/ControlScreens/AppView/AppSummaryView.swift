//
//  AppSummaryView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 28/01/2021.
//  Copyright © 2021 Paul Hudson. All rights reserved.
//

import SwiftUI

struct AppSummaryView: View {
    let application: Application

    var body: some View {
        HStack {
            AppIcon(application: application, width: 60)

            VStack(alignment: .leading) {
                Text(application.displayName)
                    .font(.headline)
                Text(application.versionNumber.isNotEmpty ? "Version \(application.versionNumber)" : "")
                    .font(.caption)
                Text(application.buildNumber.isNotEmpty ? "Build \(application.buildNumber)" : "")
                    .font(.caption)
            }
        }
    }
}

struct AppSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        AppSummaryView(application: Application.default)
    }
}
