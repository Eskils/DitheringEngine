//
//  DocumentPicker.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 17/03/2023.
//

import SwiftUI

struct DocumentPicker: UIViewControllerRepresentable {

    @Binding var image: UIImage?

    func makeCoordinator() -> DocumentPicker.Coordinator {
        return DocumentPicker.Coordinator(parent: self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: DocumentPicker.UIViewControllerType, context: UIViewControllerRepresentableContext<DocumentPicker>) {
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {

        var parent: DocumentPicker

        init(parent: DocumentPicker){
            self.parent = parent

        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            controller.dismiss(animated: true)
            
            if let data = try? Data(contentsOf: urls[0]),
               let image = UIImage(data: data) {
                self.parent.image = image
            }

        }

    }

}
