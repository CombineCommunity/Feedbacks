//
//  ActivityIndicatorView.swift
//  SwiftUIMovieDB
//
//  Created by Thibault Wittemberg on 2019-06-08.
//  Copyright © 2019 Thibault Wittemberg. All rights reserved.
//
import UIKit
import SwiftUI

struct ActivityIndicatorView: UIViewRepresentable {
    
    var isLoading: Bool = true
    let style: UIActivityIndicatorView.Style
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(frame: .zero)
        indicator.hidesWhenStopped = true
        indicator.style = style
        return indicator
    }
    
    func updateUIView(_ view: UIActivityIndicatorView, context: Context) {
        if self.isLoading {
            view.startAnimating()
        } else {
            view.stopAnimating()
        }
    }
}
