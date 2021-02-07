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
                               destination: CounterApp.RootView(
                                system: CounterApp
                                    .System
                                    .counter
                                    .uiSystem()
                                    .run()
                               ))

                NavigationLink("Giphy Trends Application",
                               destination: GifList.RootView(
                                system: GifList
                                    .System
                                    .gifOverview
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
