//
//  GifDetail+ViewState.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-19.
//

import AVKit
import Feedbacks
import SwiftUI

extension GifDetail {
    struct RootView: View {

        @ObservedObject var system: UISystem<GifDetail.ViewState.Value>

        @Environment(\.presentationMode) var presentationMode

        var body: some View {
            VStack(alignment: .trailing) {
                Button {
                    self.presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.black)
                }
                .padding()

                self.makeView(basedOn: self.system.state)
            }
        }

        @ViewBuilder
        private func makeView(basedOn state: GifDetail.ViewState.Value) -> some View {
            switch state {
            case .displayLoading: self.loadingView
            case let .displayLoaded(item): self.makeLoadedView(item: item,togglingFavorite: false)
            case let .displayTogglingFavorite(item): self.makeLoadedView(item: item,togglingFavorite: true)
            case .displayError: self.errorView
            }
        }

        private func makeLoadedView(item: GifDetail.ViewState.Item, togglingFavorite: Bool) -> some View {
            VStack {
                List {
                    HStack {
                        Text("Title:")
                        Text(item.title)
                    }
                    HStack {
                        Text("Type:")
                        Text(item.type)
                    }
                    HStack {
                        Text("Rating:")
                        Text(item.rating)
                    }
                    HStack {
                        Text("User:")
                        Text(item.user)
                    }
                    HStack {
                        Text("Favorite:")
                        if togglingFavorite {
                            ActivityIndicatorView(style: .medium)
                        } else {
                            Image(systemName: item.favorite)
                                .onTapGesture {
                                    self.system.emit(GifDetail.Events.ToggleFavorite())
                                }
                        }

                    }
                }

                Spacer()

                VideoPlayer(player: AVPlayer(url:  URL(string: item.videoUrl)!))
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding()

                Spacer()
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
    }
}

struct GifDetailRootView_Previews: PreviewProvider {
    static var previews: some View {
        GifDetail.RootView(
            system: GifDetail.System.make(id: "1").uiSystem(viewStateFactory: GifDetail.ViewState.stateToViewState(state:))
        )
    }
}
