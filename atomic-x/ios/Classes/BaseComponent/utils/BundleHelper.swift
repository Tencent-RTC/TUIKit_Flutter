public class BundleHelper {
    public static func atomicXBundle() -> Bundle {
        let bundlePath = getBundlePath(bundleName: "AtomicXBundle", classType: BundleHelper.self, frameworkName: "")
        guard let atomicXBundle = Bundle(path: bundlePath) else {
            return Bundle.main
        }
        return atomicXBundle
    }

    public static func findLocalizableBundle(bundleName: String, classType: AnyClass, language: String, frameworkName: String) -> Bundle? {
        var bundleCache: [String: Bundle] = [:]
        let languageDir = "Localizable/\(language)"
        let cacheKey = "\(bundleName)_\(languageDir)"
        var bundle = bundleCache[cacheKey]
        if bundle == nil {
            let bundlePath = getBundlePath(bundleName: bundleName, classType: classType, frameworkName: frameworkName)
            if let path = Bundle(path: bundlePath)?.path(forResource: languageDir, ofType: "lproj") {
                bundle = Bundle(path: path)
                if let bundle = bundle {
                    bundleCache[cacheKey] = bundle
                }
            }
        }
        return bundle
    }

    public static func getBundlePath(bundleName: String, classType: AnyClass, frameworkName: String) -> String {
        var bundlePathCache: [String: String] = [:]
        let classTypeString = NSStringFromClass(classType)
        let bundlePathKey = "\(bundleName)_\(classTypeString)"
        if let bundlePath = bundlePathCache[bundlePathKey] {
            return bundlePath
        }
        // Find target in the main bundle.
        var bundlePath = Bundle.main.path(forResource: bundleName, ofType: "bundle")
        // Find target in the custom bundle.
        if bundlePath == nil || bundlePath?.isEmpty == true {
            let frameworkBundlePath = Bundle(for: classType).path(forResource: frameworkName, ofType: "bundle")
            if let frameworkBundle = Bundle(path: frameworkBundlePath ?? "") {
                bundlePath = frameworkBundle.path(forResource: bundleName, ofType: "bundle")
            }
        }
        // Fing target in the specified Frameworks/{frameworkName} dir.
        if (bundlePath == nil || bundlePath?.isEmpty == true) && !frameworkName.isEmpty {
            var path = Bundle.main.bundlePath
            path = (path as NSString).appendingPathComponent("Frameworks")
            path = (path as NSString).appendingPathComponent(frameworkName)
            path = (path as NSString).appendingPathExtension("framework") ?? path
            path = (path as NSString).appendingPathComponent(bundleName)
            bundlePath = (path as NSString).appendingPathExtension("bundle")
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
