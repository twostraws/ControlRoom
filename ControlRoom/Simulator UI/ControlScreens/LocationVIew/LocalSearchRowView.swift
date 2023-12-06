//
//  LocalSearchRowView.swift
//  ControlRoom
//
//  Created by John McEvoy on 29/11/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import SwiftUI
import CoreLocation

struct LocalSearchRowView: View {
    @Binding var lastHoverId: UUID?
    @State private var isHovered = false
    let result: LocalSearchResult
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {

                Image(systemName: "mappin.circle.fill")
                    .symbolRenderingMode(.multicolor)
                        .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let subtitle = result.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
        }
        .buttonStyle(.borderless)
        .frame(minHeight: 36)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isHovered ? .blue : .clear)
        .cornerRadius(8)
        .onChange(of: lastHoverId) {
            isHovered = $0 == result.id
        }
    }
}
