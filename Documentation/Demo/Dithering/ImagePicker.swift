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
    
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        
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
            
            if let item = results.first?.itemProvider,
               item.canLoadObject(ofClass: UIImage.self) {
                
                item.loadObject(ofClass: UIImage.self) { image, _ in
                    self.imagePicker.image = image as? UIImage
                }
                
            } else {
                self.imagePicker.image = nil
            }
            
        }
        
    }
    
    
}
