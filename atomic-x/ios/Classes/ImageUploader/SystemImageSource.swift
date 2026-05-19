/*
 * Copyright (c) 2025 Tencent
 * All rights reserved.
 *
 * Author: eddardliu
 */

import UIKit
import Photos
import PhotosUI

class SystemImageSource: NSObject {
    
    private weak var presenter: UIViewController?
    private var completion: ((String?) -> Void)?
    
    func pick(source: String, from presenter: UIViewController, completion: @escaping (String?) -> Void) {
        self.presenter = presenter
        self.completion = completion
        
        switch source {
        case "camera":
            presentCamera(from: presenter)
        default:
            presentPhotoPicker(from: presenter)
        }
    }
    
    // MARK: - Camera
    
    private func presentCamera(from presenter: UIViewController) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            finish(with: nil)
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        presenter.present(picker, animated: true)
    }
    
    // MARK: - Photo Library
    
    private func presentPhotoPicker(from presenter: UIViewController) {
        if #available(iOS 14, *) {
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 1
            config.preferredAssetRepresentationMode = .current
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            picker.modalPresentationStyle = .fullScreen
            presenter.present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.image"]
            picker.delegate = self
            picker.modalPresentationStyle = .fullScreen
            presenter.present(picker, animated: true)
        }
    }
    
    // MARK: - Image Processing
    
    private func saveImageToLocal(_ image: UIImage?) -> String? {
        guard let image = image, let data = image.pngData() else { return nil }
        let tempDir = NSTemporaryDirectory() + "ImageUploader/"
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timeStamp = formatter.string(from: Date())
        let random = Int.random(in: 0..<Int.max)
        let fileName = "IMG_\(timeStamp)_\(random).png"
        let path = tempDir + fileName
        do {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            return path
        } catch {
            return nil
        }
    }
    
    private func finish(with localPath: String?) {
        completion?(localPath)
        completion = nil
        presenter = nil
    }
}

// MARK: - UIImagePickerControllerDelegate (Camera & legacy photo library)
extension SystemImageSource: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            let path = self?.saveImageToLocal(image)
            self?.finish(with: path)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.finish(with: nil)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate (iOS 14+)
@available(iOS 14, *)
extension SystemImageSource: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let first = results.first,
              first.itemProvider.canLoadObject(ofClass: UIImage.self) else {
            picker.dismiss(animated: true) { [weak self] in
                self?.finish(with: nil)
            }
            return
        }
        first.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                picker.dismiss(animated: false) {
                    let path = self?.saveImageToLocal(object as? UIImage)
                    self?.finish(with: path)
                }
            }
        }
    }
}
