//
//  documentURLForFile.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import Foundation

func documentUrlForFile(withName name: String, storing data: Data) throws -> URL {
    let fs = FileManager.default
    let documentDirectoryUrl = try fs.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let fileUrl = documentDirectoryUrl.appendingPathComponent(name)
    
    try data.write(to: fileUrl)
    
    return fileUrl
}
