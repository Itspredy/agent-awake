import Foundation

extension Bundle {
    var versionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var buildString: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }
}
