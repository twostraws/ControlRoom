//
//  ContextMenu.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/15/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

extension ContextMenu {
    init?(shouldDisplay: Bool, @ViewBuilder menuItems: () -> MenuItems) {
        guard shouldDisplay == true else { return nil }
        self.init(menuItems: menuItems)
    }
}
