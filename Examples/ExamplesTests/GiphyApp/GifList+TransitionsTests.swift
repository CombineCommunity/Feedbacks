//
//  GifList+TransitionsTests.swift
//  ExamplesTests
//
//  Created by Thibault Wittemberg on 2021-02-28.
//

@testable import Examples
import Feedbacks
import FeedbacksTest
import XCTest

final class GifList_TransitionsTests: XCTestCase {
    let mockGifOverview = (GifOverview(type: "type", id: "id", title: "title", url: "url"), true)

    func testTransitions_fromLoading_onLoadingIsComplete() {
        let sut = GifList.System.gifs.transitions

        sut.assertThat(from: GifList.States.Loading(page: 1),
                       on: GifList.Events.LoadingIsComplete(gifs: [self.mockGifOverview], currentPage: 1, totalPage: 10),
                       newStateIs: GifList.States.Loaded(gifs: [self.mockGifOverview], currentPage: 1, totalPage: 10))
    }

    func testTransitions_fromLoading_onLoadingHadFailed() {
        let sut = GifList.System.gifs.transitions

        sut.assertThat(from: GifList.States.Loading(page: 1),
                       on: GifList.Events.LoadingHasFailed(),
                       newStateIs: GifList.States.Failed())
    }

    func testTransitions_fromLoaded_onRefresh() {
        let sut = GifList.System.gifs.transitions

        sut.assertThat(from: GifList.States.Loaded(gifs: [self.mockGifOverview], currentPage: 1, totalPage: 10),
                       on: GifList.Events.Refresh(),
                       newStateIs: GifList.States.Loading(page: 1))
    }

    func testTransitions_fromLoaded_onLoadPrevious() {
        let sut = GifList.System.gifs.transitions

        sut.assertThat(from: GifList.States.Loaded(gifs: [self.mockGifOverview], currentPage: 2, totalPage: 10),
                       on: GifList.Events.LoadPrevious(),
                       newStateIs: GifList.States.Loading(page: 1))
    }

    func testTransitions_fromLoaded_onLoadPrevious_when_page0() {
        let sut = GifList.System.gifs.transitions

        sut.assertThat(from: GifList.States.Loaded(gifs: [self.mockGifOverview], currentPage: 0, totalPage: 10),
                       on: GifList.Events.LoadPrevious(),
                       newStateIs: GifList.States.Loading(page: 0))
    }

    func testTransitions_fromLoaded_onLoadNext() {
        let sut = GifList.System.gifs.transitions

        sut.assertThat(from: GifList.States.Loaded(gifs: [self.mockGifOverview], currentPage: 2, totalPage: 10),
                       on: GifList.Events.LoadNext(),
                       newStateIs: GifList.States.Loading(page: 3))
    }

    func testTransitions_fromLoaded_onLoadNext_when_pageMax() {
        let sut = GifList.System.gifs.transitions

        sut.assertThat(from: GifList.States.Loaded(gifs: [self.mockGifOverview], currentPage: 10, totalPage: 10),
                       on: GifList.Events.LoadNext(),
                       newStateIs: GifList.States.Loading(page: 10))
    }

    func testTransitions_fromFailed_onRefresh() {
        let sut = GifList.System.gifs.transitions

        sut.assertThat(from: GifList.States.Failed(),
                       on: GifList.Events.Refresh(),
                       newStateIs: GifList.States.Loading())
    }
}
