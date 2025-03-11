//
//  DocumentPicker.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 17/03/2023.
//

#if canImport(UIKit)
import SwiftUI

struct DocumentPicker: UIViewControllerRepresentable {

    @Binding
    var selection: MediaFormat?

    func makeCoordinator() -> DocumentPicker.Coordinator {
        return DocumentPicker.Coordinator(parent: self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .video, .mpeg4Movie, .movie])
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
            
            let url = urls[0]
            
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                self.parent.selection = .image(image)
            } else {
                self.parent.selection = .video(url)
            }

        }

    }

}
#endif
