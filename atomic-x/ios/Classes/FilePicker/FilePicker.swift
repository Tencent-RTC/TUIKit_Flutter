import Foundation
import UIKit
import UniformTypeIdentifiers
import os.log

public struct FilePickerConfig {
    var maxCount: Int = 1
    var allowedTypes: [String] = []
    
    public init(maxCount: Int = 1, allowedTypes: [String] = []) {
        self.maxCount = maxCount
        self.allowedTypes = allowedTypes
    }
}

public class FilePicker: NSObject, UIDocumentPickerDelegate {
    private let logger = Logger(subsystem: "FilePicker", category: "Core")
    
    public static let shared = FilePicker()
    
    public var onFilePicked: ((_ filePaths: [String]) -> Void)?
    public var onCanceled: (() -> Void)?
    
    private weak var presentingViewController: UIViewController?
    private var currentConfig: FilePickerConfig?
    
    private override init() {
        super.init()
    }
    
    public func pickFiles(config: FilePickerConfig) {
        logger.info("pickFiles called with maxCount: \(config.maxCount)")
        
        self.currentConfig = config
        
        // Get root view controller - iOS 13+ compatible
        guard let rootViewController = getRootViewController() else {
            logger.error("No root view controller found")
            onCanceled?()
            return
        }
        
        self.presentingViewController = rootViewController
        
        // Create document picker
        let documentPicker: UIDocumentPickerViewController
        
        if #available(iOS 14.0, *) {
            let contentTypes = getContentTypes(from: config.allowedTypes)
            // Use asCopy: true to enable file selection and copy mode
            // Without asCopy: true, the picker opens files for viewing instead of selecting
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        } else {
            let documentTypes = config.allowedTypes.isEmpty ? ["public.item"] : config.allowedTypes
            documentPicker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
        }
        
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = config.maxCount > 1
        
        // Present on main thread
        DispatchQueue.main.async { [weak self] in
            self?.presentingViewController?.present(documentPicker, animated: true)
        }
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        logger.info("Picked \(urls.count) documents")
        
        var filePaths: [String] = []
        
        for url in urls {
            let securityScoped = url.startAccessingSecurityScopedResource()
            defer {
                if securityScoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Copy file to app's documents directory
            if let copiedPath = copyFileToDocuments(url: url) {
                filePaths.append(copiedPath)
            } else {
                logger.error("Failed to copy file: \(url.lastPathComponent)")
            }
        }
        
        if filePaths.isEmpty {
            logger.warning("No files were successfully copied")
            onCanceled?()
        } else {
            onFilePicked?(filePaths)
        }
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        logger.info("Document picker was cancelled")
        onCanceled?()
    }
    
    // MARK: - Helper Methods
    
    private func getRootViewController() -> UIViewController? {
        var rootViewController: UIViewController?
        
        if #available(iOS 13.0, *) {
            // iOS 13+ 使用 scene-based approach
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                rootViewController = keyWindow.rootViewController
            } else {
                // Fallback to first window
                rootViewController = UIApplication.shared.windows.first?.rootViewController
            }
        } else {
            // iOS 12 及以下
            rootViewController = UIApplication.shared.keyWindow?.rootViewController
        }
        
        // Find the topmost presented view controller
        return getTopmostViewController(from: rootViewController)
    }
    
    /// Recursively find the topmost presented view controller
    private func getTopmostViewController(from viewController: UIViewController?) -> UIViewController? {
        guard let vc = viewController else { return nil }
        
        if let presented = vc.presentedViewController {
            return getTopmostViewController(from: presented)
        }
        
        if let navigationController = vc as? UINavigationController {
            return getTopmostViewController(from: navigationController.visibleViewController)
        }
        
        if let tabBarController = vc as? UITabBarController {
            return getTopmostViewController(from: tabBarController.selectedViewController)
        }
        
        return vc
    }
    
    @available(iOS 14.0, *)
    private func getContentTypes(from allowedTypes: [String]) -> [UTType] {
        if allowedTypes.isEmpty {
            return [.item]
        }
        
        var contentTypes: [UTType] = []
        for typeString in allowedTypes {
            // Try to parse as UTType identifier
            if let utType = UTType(typeString) {
                contentTypes.append(utType)
            } else if let utType = UTType(filenameExtension: typeString.replacingOccurrences(of: ".", with: "")) {
                contentTypes.append(utType)
            }
        }
        
        return contentTypes.isEmpty ? [.item] : contentTypes
    }
    
    private func copyFileToDocuments(url: URL) -> String? {
        do {
            let fileManager = FileManager.default
            let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let filesDirectory = documentsDirectory.appendingPathComponent("files", isDirectory: true)
            
            // Create files directory if it doesn't exist
            if !fileManager.fileExists(atPath: filesDirectory.path) {
                try fileManager.createDirectory(at: filesDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Generate unique filename
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            let fileName = url.lastPathComponent
            let uniqueFileName = "\(timestamp)_\(fileName)"
            let destinationURL = filesDirectory.appendingPathComponent(uniqueFileName)
            
            // Remove existing file if it exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Copy file
            try fileManager.copyItem(at: url, to: destinationURL)
            
            logger.info("File copied to: \(destinationURL.path)")
            return destinationURL.path
            
        } catch {
            logger.error("Error copying file: \(error.localizedDescription)")
            return nil
        }
    }
}
