//
//  GifDetail+TransitionsTests.swift
//  ExamplesTests
//
//  Created by Thibault Wittemberg on 2021-02-28.
//

@testable import Examples
import Feedbacks
import FeedbacksTest
import XCTest

final class GifDetail_TransitionsTests: XCTestCase {
    let mockGif = Gif(type: "type",
                  id: "id",
                  title: "title",
                  url: "url",
                  username: "username",
                  rating: "rating",
                  images: Images(fixedHeightData: ImageData(url: "url", mp4: "mp4")))
    
    func testTransitions_fromLoading_onLoadingIsComplete() {
        let sut = GifDetail.System.make(id: self.mockGif.id).transitions

        sut.assertThat(from: GifDetail.States.Loading(),
                       on: GifDetail.Events.LoadingIsComplete(gif: self.mockGif, isFavorite: true),
                       newStateIs: GifDetail.States.Loaded(gif: self.mockGif, isFavorite: true))
    }

    func testTransitions_fromLoading_onLoadingHasFailed() {
        let sut = GifDetail.System.make(id: self.mockGif.id).transitions

        sut.assertThat(from: GifDetail.States.Loading(),
                       on: GifDetail.Events.LoadingHasFailed(),
                       newStateIs: GifDetail.States.Failed())
    }

    func testTransitions_fromLoaded_onToggleFavorite() {
        let sut = GifDetail.System.make(id: self.mockGif.id).transitions

        sut.assertThat(from: GifDetail.States.Loaded(gif: self.mockGif, isFavorite: true),
                       on: GifDetail.Events.ToggleFavorite(),
                       newStateIs: GifDetail.States.TogglingFavorite(gif: self.mockGif, isFavorite: false))
    }

    func testTransitions_fromTogglingFavorite_onLoadingIsComplete() {
        let sut = GifDetail.System.make(id: self.mockGif.id).transitions

        sut.assertThat(from: GifDetail.States.TogglingFavorite(gif: self.mockGif, isFavorite: true),
                       on: GifDetail.Events.LoadingIsComplete(gif: self.mockGif, isFavorite: true),
                       newStateIs: GifDetail.States.Loaded(gif: self.mockGif, isFavorite: true))
    }

    func testTransitions_fromTogglingFavorite_onLoadingHasFailed() {
        let sut = GifDetail.System.make(id: self.mockGif.id).transitions

        sut.assertThat(from: GifDetail.States.TogglingFavorite(gif: self.mockGif, isFavorite: true),
                       on: GifDetail.Events.LoadingHasFailed(),
                       newStateIs: GifDetail.States.Failed())
    }
}
