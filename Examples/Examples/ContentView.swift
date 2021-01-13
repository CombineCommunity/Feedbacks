//
//  ContentView.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-12.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: CounterHomeView(
                        system: CounterApp.System.counter
                            .uiSystem(viewStateFactory: CounterApp.ViewState.stateToViewState(state:))
                            .run()
                    ),
                    label: {
                        Text("Counter Application")
                    })
            }
            .navigationBarTitle("Examples")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
