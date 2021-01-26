//
//  HLine.swift
//  ControlRoom
//
//  Created by Patrick Luddy on 2/19/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct HLine: NSViewRepresentable {
    func makeNSView(context: Context) -> NSBox {
        let hline = NSBox()
        hline.boxType = .separator

        return hline
    }

    func updateNSView(_ nsView: NSBox, context: Context) { }
}
