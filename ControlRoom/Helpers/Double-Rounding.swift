//
//  Double-Rounding.swift
//  ControlRoom
//
//  Created by Paul Hudson on 16/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation

extension Double {
    // Rounds a Double to a specific number of decimal places, leaving
    // it as a Double.
    func rounded(dp decimalPlaces: Int) -> Double {
        let divisor = pow(10.0, Double(decimalPlaces))
        return (self * divisor).rounded() / divisor
    }
}
