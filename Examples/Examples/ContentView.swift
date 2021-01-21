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
                NavigationLink("Counter Application",
                               destination: CounterHomeView(
                                system: CounterApp.System.counter
                                    .uiSystem(viewStateFactory: CounterApp.ViewState.stateToViewState(state:))
                                    .run()
                               ))

                NavigationLink("Giphy Trends Application",
                               destination: GifList.RootView(
                                system: GifList.System.make()
                                    .uiSystem(viewStateFactory: GifList.ViewState.stateToViewState(state:))
                                    .run()
                               ))
            }.navigationTitle("Examples")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
