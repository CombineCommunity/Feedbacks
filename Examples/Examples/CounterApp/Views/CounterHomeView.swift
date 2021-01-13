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
    var system: UISystem<CounterApp.ViewState.Value>

    var body: some View {
        VStack {
            HStack {
                Text("state = \(self.system.state.description)")
                    .font(.footnote)
                    .padding()
                Spacer()
            }
            Spacer()
            Text("\(self.system.state.counterValue)")
                .font(.system(size: 59))
                .foregroundColor(self.system.state.counterColor)
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
                .opacity(self.system.state.isCounterFixed ? 0.5 : 1.0)
                .foregroundColor(.white)
                .cornerRadius(20)
                .disabled(self.system.state.isCounterFixed)
                .animation(.default)

                Spacer()

                Button(action: {
                    self.system.emit(CounterApp.Events.TogglePause())
                }) {
                    Text("\(self.system.state.isCounterPaused ? "Start": "Stop")")
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
}

struct CounterHomeView_Previews: PreviewProvider {
    static var previews: some View {
        CounterHomeView(
            system: CounterApp.System.counter.uiSystem(viewStateFactory: CounterApp.ViewState.stateToViewState(state:))
        )
    }
}
