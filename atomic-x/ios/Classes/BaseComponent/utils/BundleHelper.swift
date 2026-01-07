public class BundleHelper {
    // 静态缓存变量，确保在整个应用生命周期中保持
    private static var bundleCache: [String: Bundle] = [:]
    private static var bundlePathCache: [String: String] = [:]
    
    /// 调试辅助方法：递归搜索 bundle
    private static func findBundleRecursively(bundleName: String, in directory: String) -> String? {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: directory) else {
            return nil
        }
        
        let targetName = "\(bundleName).bundle"
        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(targetName) || file == targetName {
                let fullPath = (directory as NSString).appendingPathComponent(file)
                if fileManager.fileExists(atPath: fullPath) {
                    return fullPath
                }
            }
        }
        return nil
    }
    
    public static func atomicXBundle() -> Bundle {
        let bundlePath = getBundlePath(bundleName: "AtomicXBundle", classType: BundleHelper.self, frameworkName: "")
        guard let atomicXBundle = Bundle(path: bundlePath) else {
            return Bundle.main
        }
        return atomicXBundle
    }

    public static func findLocalizableBundle(bundleName: String, classType: AnyClass, language: String, frameworkName: String) -> Bundle? {
        let languageDir = "Localizable/\(language)"
        let cacheKey = "\(bundleName)_\(languageDir)"
        
        let bundlePath = getBundlePath(bundleName: bundleName, classType: classType, frameworkName: frameworkName)
        
        guard let mainBundle = Bundle(path: bundlePath) else {
            return nil
        }
        
        guard let lprojPath = mainBundle.path(forResource: languageDir, ofType: "lproj") else {
            return nil
        }
        
        let bundle = Bundle(path: lprojPath)
        if let bundle = bundle {
            bundleCache[cacheKey] = bundle
        }
        return bundle
    }

    public static func getBundlePath(bundleName: String, classType: AnyClass, frameworkName: String) -> String {
        let classTypeString = NSStringFromClass(classType)
        let bundlePathKey = "\(bundleName)_\(classTypeString)"
        
        if let bundlePath = bundlePathCache[bundlePathKey] {
            return bundlePath
        }
        
        var bundlePath: String?
        
        // 1. 在主 bundle 中查找
        bundlePath = Bundle.main.path(forResource: bundleName, ofType: "bundle")
        
        // 2. 在 classType 的 bundle 中查找
        if bundlePath == nil || bundlePath?.isEmpty == true {
            let classBundle = Bundle(for: classType)
            bundlePath = classBundle.path(forResource: bundleName, ofType: "bundle")
        }
        
        // 3. 在 framework bundle 中查找
        if (bundlePath == nil || bundlePath?.isEmpty == true) && !frameworkName.isEmpty {
            let classBundle = Bundle(for: classType)
            if let frameworkBundlePath = classBundle.path(forResource: frameworkName, ofType: "bundle"),
               let frameworkBundle = Bundle(path: frameworkBundlePath) {
                bundlePath = frameworkBundle.path(forResource: bundleName, ofType: "bundle")
            }
        }
        
        // 4. 在 Frameworks 目录下查找
        if (bundlePath == nil || bundlePath?.isEmpty == true) && !frameworkName.isEmpty {
            var path = Bundle.main.bundlePath
            path = (path as NSString).appendingPathComponent("Frameworks")
            path = (path as NSString).appendingPathComponent(frameworkName)
            path = (path as NSString).appendingPathExtension("framework") ?? path
            path = (path as NSString).appendingPathComponent(bundleName)
            bundlePath = (path as NSString).appendingPathExtension("bundle")
            
            if let path = bundlePath, !FileManager.default.fileExists(atPath: path) {
                bundlePath = nil
            }
        }
        
        // 5. 在 Frameworks 目录中直接查找 bundle
        if bundlePath == nil || bundlePath?.isEmpty == true {
            var path = Bundle.main.bundlePath
            path = (path as NSString).appendingPathComponent("Frameworks")
            path = (path as NSString).appendingPathComponent(bundleName)
            let testPath = (path as NSString).appendingPathExtension("bundle")
            
            if FileManager.default.fileExists(atPath: testPath ?? "") {
                bundlePath = testPath
            }
        }
        
        // 6. 递归搜索整个主 bundle
        if bundlePath == nil || bundlePath?.isEmpty == true {
            let mainBundlePath = Bundle.main.bundlePath
            if let found = findBundleRecursively(bundleName: bundleName, in: mainBundlePath) {
                bundlePath = found
            }
        }
        
        if let finalPath = bundlePath {
            bundlePathCache[bundlePathKey] = finalPath
        }
        
        return bundlePath ?? ""
    }
}

public class AtomicXChatResources {
    public static let frameworkBundle = Bundle(for: AtomicXChatResources.self)
    public static var resourceBundle: Bundle {
        if let bundlePath = frameworkBundle.path(forResource: "AtomicXBundle", ofType: "bundle"),
           let bundle = Bundle(path: bundlePath)
        {
            return bundle
        }
        return frameworkBundle
    }

    public static func image(named name: String) -> UIImage? {
        return UIImage(named: name, in: resourceBundle, compatibleWith: nil)
    }
}
