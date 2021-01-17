//
//  GifList+RootView.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

import Feedbacks
import SwiftUI

extension GifList {
    struct RootView: View {
        @ObservedObject
        var system: UISystem<GifList.ViewState.Value>

        var body: some View {
            NavigationView {
                self.makeView(basedOn: system.state)
                    .navigationBarTitle("Trends")
            }
        }

        @ViewBuilder
        private func makeView(basedOn viewState: GifList.ViewState.Value) -> some View {
            switch viewState {
            case .displayLoading: loadingView
            case let .displayLoaded(items, hasPrevious, hasNext): self.makeLoadedView(items: items, hasPrevious: hasPrevious, hasNext: hasNext)
            case .displayError: errorView
            }
        }

        private var loadingView: some View {
            ActivityIndicatorView(style: .large)
        }

        private var errorView: some View {
            Text("An error has occurred")
        }

        private func makeLoadedView(items: [GifList.ViewState.Item], hasPrevious: Bool, hasNext: Bool) -> some View {
            VStack {
                List(items) { item in
                    GifList.RowView(title: item.title, isFavorite: item.isFavorite)
                }.listStyle(PlainListStyle())

                HStack {
                    Button {
                        self.system.emit(GifList.Events.LoadPrevious())
                    } label: {
                        Image(systemName: "backward.fill")
                    }
                    .disabled(!hasPrevious)

                    Button {
                        self.system.emit(GifList.Events.LoadNext())
                    } label: {
                        Image(systemName: "forward.fill")
                    }
                    .disabled(!hasNext)
                }.frame(height: 50)
            }
        }
    }
}


struct GifList_RootView_Previews: PreviewProvider {
    static var previews: some View {
        GifList.RootView(system: GifList.System.make().uiSystem(viewStateFactory: GifList.ViewState.stateToViewState(state:)))
    }
}
