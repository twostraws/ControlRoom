//
//  NSColor-Conversions.swift
//  ControlRoom
//
//  Created by Paul Hudson on 16/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import AppKit

extension NSColor {
    /// The red color component rounded to a range of 0-255.
    var red255: Double { (redComponent * 255).rounded() }

    /// The green color component rounded to a range of 0-255.
    var green255: Double { (greenComponent * 255).rounded() }

    /// The blue color component rounded to a range of 0-255.
    var blue255: Double { (blueComponent * 255).rounded() }

    // NOTE: You might think the following three properties are
    // redundant, but it's just for maximum accuracy – if we used
    // the original redComponent, greenComponent, and blueComponent
    // then we would have the exact, original color, but they
    // wouldn't be exactly the same as the hex color. So, these
    // properties bounce through the 0-255 rounded variant first,
    // to try to keep colors uniform.

    /// The rounded redComponent, put back into the range of 0-1.
    var red1: Double { red255 / 255 }

    /// The rounded greenComponent, put back into the range of 0-1.
    var green1: Double { green255 / 255 }

    /// The rounded blueComponent, put back into the range of 0-1.
    var blue1: Double { blue255 / 255 }
}
