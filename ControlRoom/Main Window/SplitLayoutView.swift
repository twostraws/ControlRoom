//
//  SplitLayoutView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// A horizontal split view that shows a left-hand sidebar of simulators and right-hand details.
struct SplitLayoutView: View {
    @ObservedObject var controller: SimulatorsController

	@State var dropHovering: Bool = false

    var body: some View {
        NavigationView {
			SidebarView(controller: controller)
				.frame(minWidth: 220)
                .layoutPriority(1)

            // Use a GeometryReader here to take up as much space as possible
            // otherwise the view would collapse down to (potentially)
            // the size of the Text.
            GeometryReader { _ in
				switch controller.selectedSimulatorIDs.count {
				case 0:
					Text("Select a simulator from the list.")
						.frame(maxWidth: .infinity, maxHeight: .infinity)
				case 1:
					ControlView(controller: controller,
								simulator: controller.selectedSimulators[0],
								applications: controller.applications)
						.padding()
				default:
					Text("Drag file(s) here to copy them to each simulator's Files directory.\n(booted simulators only)")
						.multilineTextAlignment(.center)
						.padding(20)
						.overlay(
							RoundedRectangle(cornerRadius: 5)
								.stroke(dropHovering ? Color.white : Color.gray, lineWidth: 1)
						)
						.onDrop(of: [.fileURL], isTargeted: $dropHovering) { providers in
							return copyFilesFromProviders(providers, toFilePath: .files)
						}
						.frame(maxWidth: .infinity, maxHeight: .infinity)
				}

            }
            .layoutPriority(2)
        }
    }

	func copyFilesFromProviders(_ providers: [NSItemProvider], toFilePath filePath: Simulator.FilePathKind) -> Bool {
		for simulator in controller.selectedSimulators {
			_ = simulator.copyFilesFromProviders(providers, toFilePath: filePath)
		}
		return true
	}
}

struct SplitLayoutView_Previews: PreviewProvider {
    static var previews: some View {
        let preferences = Preferences()
        SplitLayoutView(controller: SimulatorsController(preferences: preferences))
            .environmentObject(preferences)
    }
}
