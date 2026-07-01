import Foundation
import ServiceManagement

enum SMAppServiceSpike {
    static let helperBundleID = "com.scottkostolni.WireBar.PrivilegedHelper"

    @available(macOS 13.0, *)
    static func registerHelper() throws {
        let service = SMAppService.daemon(plistName: "\(helperBundleID).plist")
        try service.register()
    }

    @available(macOS 13.0, *)
    static func unregisterHelper() throws {
        let service = SMAppService.daemon(plistName: "\(helperBundleID).plist")
        try service.unregister()
    }

    @available(macOS 13.0, *)
    static func helperStatus() -> SMAppService.Status {
        let service = SMAppService.daemon(plistName: "\(helperBundleID).plist")
        return service.status
    }
}
