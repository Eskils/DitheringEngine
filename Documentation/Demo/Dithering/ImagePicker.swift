//
//  ImagePicker.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 29/11/2022.
//

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = PHPickerViewController
    
    @Binding var selection: MediaFormat?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = PHPickerFilter.any(of: [.images, .videos])
        
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> ImagePickerDelegatee {
        return ImagePickerDelegatee(imagePicker: self)
    }
    
    class ImagePickerDelegatee: NSObject, PHPickerViewControllerDelegate {
        let imagePicker: ImagePicker
        
        init(imagePicker: ImagePicker) {
            self.imagePicker = imagePicker
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            
            picker.dismiss(animated: true)
            
            if let item = results.first?.itemProvider {
                if item.canLoadObject(ofClass: UIImage.self) {
                    
                    item.loadObject(ofClass: UIImage.self) { image, _ in
                        if let image = image as? UIImage {
                            self.imagePicker.selection = .image(image)
                        } else {
                            self.imagePicker.selection = nil
                        }
                    }
                } else {
                    item.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                        let videoURL = FileManager.default.temporaryDirectory.appendingPathComponent("ImportedVideo.mp4")
                        if let url,
                           FileManager.default.fileExists(atPath: url.path),
                           (try? FileManager.default.copyItem(at: url, to: videoURL)) != nil {
                            self.imagePicker.selection = .video(videoURL)
                        } else {
                            print("Could not load video: \(String(describing: error))")
                            self.imagePicker.selection = nil
                        }
                    }
                }
                
            } else {
                self.imagePicker.selection = nil
            }
            
        }
        
    }
    
    
}
