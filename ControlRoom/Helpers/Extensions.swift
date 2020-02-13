//
//  Extensions.swift
//  ControlRoom
//
//  Created by Vinay Jain on 13/02/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Foundation

extension NSTextCheckingResult {
    func groups(testedString: String) -> [String] {
        var groups = [String]()
        for index in  0 ..< self.numberOfRanges {
            let group = String(testedString[Range(self.range(at: index), in: testedString)!])
            groups.append(group)
        }
        return groups
    }
}
