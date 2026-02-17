import AppKit
import Foundation

enum Updater {
    private static let commitURL = "https://api.github.com/repos/furst/Jot/commits/main"
    private static let installScript = "https://raw.githubusercontent.com/furst/Jot/main/scripts/install.sh"

    private static var appIcon: NSImage? {
        guard let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") else { return nil }
        return NSImage(contentsOf: url)
    }

    static func checkForUpdates() {
        guard let buildCommit = Bundle.main.infoDictionary?["JotBuildCommit"] as? String,
              !buildCommit.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "Version Check Unavailable"
            alert.informativeText = "Version checking is only available for installed builds."
            alert.alertStyle = .informational
            alert.icon = appIcon
            alert.runModal()
            return
        }

        let task = URLSession.shared.dataTask(with: URLRequest(url: URL(string: commitURL)!)) { data, _, error in
            DispatchQueue.main.async {
                if let error {
                    let alert = NSAlert()
                    alert.messageText = "Update Check Failed"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.icon = appIcon
            alert.runModal()
                    return
                }

                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let remoteSHA = json["sha"] as? String else {
                    let alert = NSAlert()
                    alert.messageText = "Update Check Failed"
                    alert.informativeText = "Could not read version information from GitHub."
                    alert.alertStyle = .warning
                    alert.icon = appIcon
            alert.runModal()
                    return
                }

                if remoteSHA.hasPrefix(buildCommit) || buildCommit.hasPrefix(remoteSHA) {
                    let alert = NSAlert()
                    alert.messageText = "You're up to date!"
                    alert.informativeText = "jot is already running the latest version."
                    alert.alertStyle = .informational
                    alert.icon = appIcon
            alert.runModal()
                } else {
                    promptUpdate()
                }
            }
        }
        task.resume()
    }

    private static func promptUpdate() {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "A new version of jot is available. Update now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Update Now")
        alert.addButton(withTitle: "Later")
        alert.icon = appIcon

        if alert.runModal() == .alertFirstButtonReturn {
            performUpdate()
        }
    }

    private static func performUpdate() {
        let script = """
        #!/bin/bash
        sleep 0.5
        osascript -e 'display notification "Downloading and installing..." with title "jot"'
        curl -fsSL "\(installScript)" | bash
        osascript -e 'display notification "Update complete!" with title "jot"'
        open /Applications/jot.app
        rm -f "$0"
        """

        let fm = FileManager()
        let tempURL = fm.temporaryDirectory.appendingPathComponent("jot-update.sh")
        do {
            try script.write(to: tempURL, atomically: true, encoding: .utf8)
            try fm.setAttributes(
                [.posixPermissions: 0o755], ofItemAtPath: tempURL.path)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Update Failed"
            alert.informativeText = "Could not prepare update script: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.icon = appIcon
            alert.runModal()
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [tempURL.path]
        try? process.run()

        NSApp.terminate(nil)
    }
}
