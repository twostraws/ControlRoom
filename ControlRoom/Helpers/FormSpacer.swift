//
//  FormSpacer.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Padding sections apply their padding to all views inside the section rather than the
/// section itself, so this is a way to get uniform spacing between form components.
struct FormSpacer: View {
    var body: some View {
        VStack {
            Spacer()
                .frame(maxHeight: 15)
            HLine()
            Spacer()
                .frame(maxHeight: 15)
        }
    }
}
