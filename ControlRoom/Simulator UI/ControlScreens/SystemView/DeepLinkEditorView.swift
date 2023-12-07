//
//  DeepLinkEditorView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 16/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import SwiftUI

struct DeepLinkEditorView: View {
    @EnvironmentObject var deepLinks: DeepLinksController
    @Environment(\.dismiss) var dismiss

    /// The link name the user is currently adding.
    @State private var newLinkName = ""

    /// The link URL the user is currently adding.
    @State private var newLinkURL = ""

    /// The order we're displaying our links, defaulting to name.
    @State private var sortOrder = [KeyPathComparator(\DeepLink.name)]

    /// The currently selected deep link, or nil if nothing is selected.
    @State private var selection: DeepLink.ID?

    /// Whether we are currently showing the alert to let the user add a new deep link.
    @State private var showingAddAlert = false

    var body: some View {
        VStack {
            Text("Saved Deep Links")
                .font(.title)

            Text("Create named deep links or other URLs to make them easier to open repeatedly inside Control Room. **Tip:** Adjusting the sort order adjusts the order here, in the System tab, and in the menu bar list.")

            if deepLinks.links.isEmpty {
                Spacer()
                Text("No saved deep links created yet.")
                Spacer()
            } else {
                Table(deepLinks.links, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn("Name", value: \.name)
                    TableColumn("URL", value: \.url.absoluteString)
                }
            }

            HStack {
                Button("Add New") {
                    showingAddAlert.toggle()
                }
                Button("Delete") {
                    deleteSelected()
                }
                .disabled(selection == nil)
                Spacer()
                Button("Done") { dismiss() }
            }
        }
        .frame(width: 500)
        .frame(minHeight: 350)
        .padding()
        .alert("Add new deep link", isPresented: $showingAddAlert) {
            TextField("Name", text: $newLinkName)
            TextField("URL", text: $newLinkURL)
            Button("Add", action: addLink)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Make sure you include a schema, e.g. https:// or yourapp://")
        }
        .onChange(of: sortOrder) { newOrder in
            deepLinks.sort(using: newOrder)
        }
    }

    /// Triggered by our alert, when the user wants to save their new deep link.
    func addLink() {
        deepLinks.create(name: newLinkName, url: newLinkURL)
        newLinkName = ""
        newLinkURL = ""
    }

    /// Deletes whatever is the currently selected deep link.
    func deleteSelected() {
        deepLinks.delete(selection)
        selection = nil
    }
}

struct DeepLinkEditorView_Previews: PreviewProvider {
    static var previews: some View {
        DeepLinkEditorView()
    }
}
