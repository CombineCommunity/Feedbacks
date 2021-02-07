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
        @ObservedObject var system: UISystem<GifList.ViewState.Value>

        @SwiftUI.State private var selectedGif: String?

        var body: some View {
            self.makeView(basedOn: self.system.state)
                .navigationBarTitle("Trends", displayMode: .inline)
                .navigationBarItems(trailing: Button {
                    self.system.emit(GifList.Events.Refresh())
                }
                label: {
                    Image(systemName: "arrow.clockwise")
                })
        }

        @ViewBuilder
        private func makeView(basedOn viewState: GifList.ViewState.Value) -> some View {
            switch viewState {
            case .displayLoading: loadingView
            case let .displayLoaded(items, hasPrevious, hasNext, counter): self.makeLoadedView(items: items,
                                                                                               hasPrevious: hasPrevious,
                                                                                               hasNext: hasNext,
                                                                                               counter: counter)
            case .displayError: errorView
            }
        }

        private var loadingView: some View {
            ActivityIndicatorView(style: .large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private var errorView: some View {
            Text("An error has occurred")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private func makeLoadedView(items: [GifList.ViewState.Item], hasPrevious: Bool, hasNext: Bool, counter: String) -> some View {
            VStack {
                List(items) { item in
                    GifList.RowView(title: item.title, isFavorite: item.isFavorite)
                        .onTapGesture {
                            self.selectedGif = item.id
                        }
                }.listStyle(PlainListStyle())

                HStack {
                    Button {
                        self.system.emit(GifList.Events.LoadPrevious())
                    } label: {
                        Image(systemName: "backward.fill")
                    }
                    .disabled(!hasPrevious)

                    Text(counter)

                    Button {
                        self.system.emit(GifList.Events.LoadNext())
                    } label: {
                        Image(systemName: "forward.fill")
                    }
                    .disabled(!hasNext)
                }.frame(height: 50)
            }
            .sheet(item: self.$selectedGif) {
                self.system.emit(GifList.Events.Refresh())
            } content: { gifId in
                GifDetail.RootView(
                    system: GifDetail.System.make(id: gifId)
                        .uiSystem(viewStateFactory: GifDetail.ViewState.stateToViewState(state:))
                        .run()
                )
            }
        }
    }
}

extension String: Identifiable {
    public var id: String {
        self
    }
}

struct GifList_RootView_Previews: PreviewProvider {
    static var previews: some View {
        GifList.RootView(system: GifList.System.gifOverview.uiSystem(viewStateFactory: GifList.ViewState.stateToViewState(state:)))
    }
}
