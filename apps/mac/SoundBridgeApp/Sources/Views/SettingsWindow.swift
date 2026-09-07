import SwiftUI
import AppKit

/// Settings window for SoundBridge preferences
class SettingsWindow: NSWindow {
	init() {
		super.init(
			contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
			styleMask: [.titled, .closable],
			backing: .buffered,
			defer: false
		)

		self.title = "SoundBridge Settings"
		self.isReleasedWhenClosed = false
		self.center()
		self.contentView = NSHostingView(
			rootView: SettingsView()
		)
	}
}

struct SettingsView: View {
	@ObservedObject private var launchAtLogin = LaunchAtLoginManager.shared

	var body: some View {
		VStack(spacing: 0) {
			// Header
			VStack(spacing: 12) {
				AppIconView(size: 64)

				Text("SoundBridge")
					.font(.title)
					.fontWeight(.semibold)

				if let version = VersionManager.appVersion() {
					Text("Version \(version)")
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
			}
			.padding(.top, 30)
			.padding(.bottom, 20)

			Divider()

			// Content
			ScrollView {
				VStack(spacing: 24) {
					// General Settings Section
					VStack(alignment: .leading, spacing: 16) {
						Text("General")
							.font(.headline)
							.foregroundColor(.primary)

						VStack(alignment: .leading, spacing: 8) {
							Toggle("Launch at login", isOn: Binding(
								get: { launchAtLogin.isEnabled },
								set: { launchAtLogin.setEnabled($0) }
							))
							.toggleStyle(.checkbox)

							Text(launchAtLogin.statusDescription)
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(16)
					.background(Color.secondary.opacity(0.05))
					.cornerRadius(12)

					// System Info Section
					VStack(alignment: .leading, spacing: 16) {
						Text("System Info")
							.font(.headline)
							.foregroundColor(.primary)

						VStack(alignment: .leading, spacing: 10) {
							if let appVersion = VersionManager.appVersion() {
								InfoRow(label: "App Version", value: appVersion)
							}

							if VersionManager.isDriverInstalled() {
								if let driverVersion = VersionManager.installedDriverVersion() {
									InfoRow(label: "Driver Version", value: driverVersion)
								}
							} else {
								InfoRow(label: "Driver Status", value: "Not Installed")
									.foregroundColor(.orange)
							}

							if let installDate = OnboardingState.driverInstallDate() {
								InfoRow(label: "Driver Installed", value: formatDate(installDate))
							}
						}
					}
					.padding(16)
					.background(Color.secondary.opacity(0.05))
					.cornerRadius(12)

					// About Section
					VStack(alignment: .leading, spacing: 16) {
						Text("About")
							.font(.headline)
							.foregroundColor(.primary)

						VStack(alignment: .leading, spacing: 8) {
							Text("SoundBridge is a free, open-source system equalizer for macOS.")
								.font(.caption)
								.foregroundColor(.secondary)

							Link("Visit Website", destination: URL(string: "https://soundbridge.app")!)
								.font(.caption)
						}
					}
					.padding(16)
					.background(Color.secondary.opacity(0.05))
					.cornerRadius(12)
				}
				.padding(20)
			}
		}
		.frame(width: 500, height: 450)
		.onAppear {
			launchAtLogin.refreshStatus()
		}
	}

	private func formatDate(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter.string(from: date)
	}
}

/// Loads app-icon.png from the bundle Resources directory
struct AppIconView: View {
	let size: CGFloat

	var body: some View {
		Group {
			if let image = loadAppIcon() {
				Image(nsImage: image)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: size, height: size)
					.clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
			} else {
				Image(systemName: "waveform.circle.fill")
					.font(.system(size: size * 0.8))
					.foregroundColor(.accentColor)
			}
		}
	}

	private func loadAppIcon() -> NSImage? {
		// Try resource bundle first
		if let resourceBundleURL = Bundle.main.url(forResource: "SoundBridgeApp_SoundBridgeApp", withExtension: "bundle"),
		   let resourceBundle = Bundle(url: resourceBundleURL),
		   let path = resourceBundle.url(forResource: "app-icon", withExtension: "png") {
			return NSImage(contentsOf: path)
		}
		// Try main bundle Resources
		if let path = Bundle.main.url(forResource: "app-icon", withExtension: "png") {
			return NSImage(contentsOf: path)
		}
		// Try resourcePath directly
		if let resourcePath = Bundle.main.resourcePath {
			for subpath in ["Resources/app-icon.png", "app-icon.png"] {
				let fullPath = (resourcePath as NSString).appendingPathComponent(subpath)
				if FileManager.default.fileExists(atPath: fullPath) {
					return NSImage(contentsOfFile: fullPath)
				}
			}
		}
		return nil
	}
}

struct InfoRow: View {
	let label: String
	let value: String

	var body: some View {
		HStack {
			Text(label)
				.font(.caption)
				.foregroundColor(.secondary)
			Spacer()
			Text(value)
				.font(.caption)
				.fontWeight(.medium)
		}
	}
}
