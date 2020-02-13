//
//  LevelIndicator.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct LevelIndicator<ValueLabel: View, Label: View>: View {
    let range: ClosedRange<Double>
    @Binding var value: Double
    let onValueChanged: (Double) -> Void

    let label: Label
    let minLabel: ValueLabel
    let maxLabel: ValueLabel

    @State var labelWidth: CGFloat = 0

    init(value: Binding<Double>,
         in range: ClosedRange<Double>,
         onValueChanged: @escaping (Double) -> Void = { _ in },
         minimumValueLabel: ValueLabel,
         maximumValueLabel: ValueLabel,
         @ViewBuilder valueLabel: () -> Label) {

        _value = value
        self.range = range
        self.onValueChanged = onValueChanged

        self.label = valueLabel()
        self.minLabel = minimumValueLabel
        self.maxLabel = maximumValueLabel
    }

    var body: some View {
        HStack {
            label
                .background(WidthGetter(width: self.$labelWidth))
            Spacer()
            minLabel
            AppKitLevelIndicator(value: $value, in: range, onValueChanged: onValueChanged)
                .overlay(Text("\(Int(value))%").foregroundColor(.primary))
            maxLabel
        }.alignmentGuide(.leading, computeValue: { _ in self.labelWidth + 8 })
    }
}

extension LevelIndicator where ValueLabel == Text {
    init(value: Binding<Double>,
         in range: ClosedRange<Double>,
         onValueChanged: @escaping (Double) -> Void = { _ in },
         minimumValueLabel: String,
         maximumValueLabel: String,
         @ViewBuilder valueLabel: () -> Label) {

        self.init(value: value,
                  in: range,
                  onValueChanged: onValueChanged,
                  minimumValueLabel: Text(minimumValueLabel),
                  maximumValueLabel: Text(maximumValueLabel),
                  valueLabel: valueLabel)
    }
}

private struct WidthGetter: View {
    @Binding var width: CGFloat
    var body: some View {
        GeometryReader { proxy in
            self.createView(proxy: proxy)
        }
    }

    func createView(proxy: GeometryProxy) -> some View {
        DispatchQueue.main.async {
            self.width = proxy.size.width
        }
        return Rectangle().fill(Color.clear)
    }
}

struct AppKitLevelIndicator: NSViewRepresentable {
    let range: ClosedRange<Double>
    @Binding var value: Double
    let onValueChanged: (Double) -> Void

    init(value: Binding<Double>, in range: ClosedRange<Double>, onValueChanged: @escaping (Double) -> Void) {
        _value = value
        self.range = range
        self.onValueChanged = onValueChanged
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(binding: $value, onChange: onValueChanged)
    }

    func makeNSView(context: Context) -> NSLevelIndicator {
        let view = NSLevelIndicator()
        view.minValue = range.lowerBound
        view.maxValue = range.upperBound
        view.levelIndicatorStyle = .continuousCapacity

        // critical value occurs at <= 10%
        // warning level occurs at <= 50%
        view.criticalValue = range.lowerBound + (range.upperBound - range.lowerBound) * 0.1
        view.criticalFillColor = .red

        view.warningValue = range.lowerBound + (range.upperBound - range.lowerBound) * 0.5
        view.warningFillColor = .orange

        view.fillColor = .green

        view.isEditable = true
        view.target = context.coordinator
        view.action = #selector(Coordinator.action(_:))
        view.isContinuous = false
        return view
    }

    func updateNSView(_ nsView: NSLevelIndicator, context: Context) {
        nsView.doubleValue = value
    }

    class Coordinator: NSObject {
        let binding: Binding<Double>
        let onChange: (Double) -> Void

        init(binding: Binding<Double>, onChange: @escaping (Double) -> Void) {
            self.binding = binding
            self.onChange = onChange
            super.init()
        }

        @objc func action(_ sender: NSLevelIndicator) {
            binding.wrappedValue = sender.doubleValue
            onChange(sender.doubleValue)
        }
    }
}

struct LevelIndicator_Previews: PreviewProvider {
    @State static var value: Double = 1.0

    static var previews: some View {
        LevelIndicator(value: $value, in: 0 ... 1.0, minimumValueLabel: "0", maximumValueLabel: "1") { Text("Label") }
    }
}
