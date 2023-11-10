//
//  MediaFormat.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 09/11/2023.
//

import UIKit

enum MediaFormat {
    case image(UIImage)
    case video(URL)
}

extension MediaFormat: Equatable {}
