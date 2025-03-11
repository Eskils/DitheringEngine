//
//  DocumentExporter.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 18/11/2023.
//

#if canImport(UIKit)
import SwiftUI

struct DocumentExporter: UIViewControllerRepresentable {

    var exporting: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentExporter>) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [exporting])
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentExporter>) {
    }

}
#endif
