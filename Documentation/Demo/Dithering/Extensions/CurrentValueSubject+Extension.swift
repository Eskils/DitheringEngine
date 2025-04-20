//
//  CurrentValueSubject+Extension.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import Combine
import SwiftUI

extension CurrentValueSubject {
  var binding: Binding<Output> {
    Binding(get: {
      self.value
    }, set: {
      self.send($0)
    })
  }
}
