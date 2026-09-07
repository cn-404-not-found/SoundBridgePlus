import Foundation
import ServiceManagement
import Combine

/// Manages macOS launch-at-login state using SMAppService (macOS 13+)
@MainActor
final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published var isEnabled: Bool = false
    @Published var statusDescription: String = ""

    private init() {
        refreshStatus()
    }

    /// Refreshes current launch-at-login status from system service
    func refreshStatus() {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            isEnabled = (status == .enabled)
            switch status {
            case .enabled:
                statusDescription = "Enabled"
            case .requiresApproval:
                statusDescription = "Requires approval in System Settings → Login Items"
            case .notRegistered, .notFound:
                statusDescription = "Disabled"
            @unknown default:
                statusDescription = "Disabled"
            }
        }
    }

    /// Toggles launch-at-login registration
    func setEnabled(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
                        try SMAppService.mainApp.unregister()
                    }
                }
                refreshStatus()
            } catch {
                print("[LaunchAtLogin] Failed to change status: \(error)")
                statusDescription = "Failed: \(error.localizedDescription)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.refreshStatus()
                }
            }
        }
    }
}
