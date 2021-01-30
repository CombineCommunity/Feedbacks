//
//  CounterHomeView.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-12.
//

import Feedbacks
import SwiftUI

struct CounterHomeView: View {

    @ObservedObject
    var system: UISystem<RawState>

    var body: some View {
        VStack {
            HStack {
                Text("state = \(self.counterDescription(from: self.system.state))")
                    .font(.footnote)
                    .padding()
                Spacer()
            }
            Spacer()
            Text("\(self.counterValue(from: self.system.state))")
                .font(.system(size: 59))
                .foregroundColor(self.counterColor(from: self.system.state))
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    self.system.emit(CounterApp.Events.Reset(value: 10))
                }) {
                    Text("Reset")
                        .font(.system(size: 25))
                }
                .frame(width: 100, height: 30, alignment: .center)
                .padding(10)
                .background(Color.gray)
                .opacity(self.isCounterFixed(from: self.system.state) ? 0.5 : 1.0)
                .foregroundColor(.white)
                .cornerRadius(20)
                .disabled(self.isCounterFixed(from: self.system.state))
                .animation(.default)

                Spacer()

                Button(action: {
                    self.system.emit(CounterApp.Events.TogglePause())
                }) {
                    Text("\(self.isCounterPaused(from: self.system.state) ? "Start": "Stop")")
                        .font(.system(size: 25))
                }
                .frame(width: 100, height: 30, alignment: .center)
                .padding(10)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(20)

                Spacer()
            }
            .padding(20)
        }
        .padding(20)
    }

    private func counterValue(from rawState: RawState) -> Int {
        switch rawState.state {
        case let fixed as CounterApp.States.Fixed: return fixed.value
        case let decreasing as CounterApp.States.Decreasing: return decreasing.value
        case let increasing as CounterApp.States.Increasing: return increasing.value
        default: return 0
        }
    }

    private func counterColor(from rawState: RawState) -> Color {
        switch rawState.state {
        case is CounterApp.States.Fixed: return .green
        case is CounterApp.States.Decreasing: return .red
        case is CounterApp.States.Increasing: return .blue
        default: return .accentColor
        }
    }

    private func isCounterFixed(from rawState: RawState) -> Bool {
        guard rawState.state is CounterApp.States.Fixed else { return false }
        return true
    }

    private func isCounterPaused(from rawState: RawState) -> Bool {
        switch rawState.state {
        case is CounterApp.States.Fixed: return true
        case let decreasing as CounterApp.States.Decreasing: return decreasing.isPaused
        case let increasing as CounterApp.States.Increasing: return increasing.isPaused
        default: return true
        }
    }

    private func counterDescription(from rawState: RawState) -> String {
        switch rawState.state {
        case let fixed as CounterApp.States.Fixed:
            return "Fixed(value: \(fixed.value)"
        case let decreasing as CounterApp.States.Decreasing:
            return "Decreasing(value: \(decreasing.value), paused: \(decreasing.isPaused)"
        case let increasing as CounterApp.States.Increasing:
            return "Increasing(value: \(increasing.value), paused: \(increasing.isPaused)"
        default: return "undefined"
        }
    }
}

struct CounterHomeView_Previews: PreviewProvider {
    static var previews: some View {
        CounterHomeView(system: CounterApp.System.counter)
    }
}
