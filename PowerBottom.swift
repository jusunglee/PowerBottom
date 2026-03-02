import Cocoa
import CoreGraphics

// MARK: - Display Manager

class DisplayManager {
    var enabled = true
    private var knownDisplayIDs: Set<CGDirectDisplayID> = []
    private var pendingArrangement = false

    func start() {
        knownDisplayIDs = Set(activeDisplays())
        CGDisplayRegisterReconfigurationCallback({ _, flags, ctx in
            let mgr = Unmanaged<DisplayManager>.fromOpaque(ctx!).takeUnretainedValue()
            mgr.onReconfigure(flags)
        }, Unmanaged.passUnretained(self).toOpaque())
        NSLog("PowerBottom: watching for new displays (%d currently active)", knownDisplayIDs.count)
    }

    private func activeDisplays() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &ids, &count)
        return Array(ids.prefix(Int(count)))
    }

    private func onReconfigure(_ flags: CGDisplayChangeSummaryFlags) {
        // When a display is removed, update known set so re-plugging is detected as new
        if flags.contains(.removeFlag) && !flags.contains(.beginConfigurationFlag) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                knownDisplayIDs = Set(activeDisplays())
                NSLog("PowerBottom: display removed, tracking %d displays", knownDisplayIDs.count)
            }
            return
        }

        guard enabled else { return }
        guard flags.contains(.addFlag), !pendingArrangement else { return }
        pendingArrangement = true

        // Wait for macOS to finish configuring the new display
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
            defer { pendingArrangement = false }
            let current = Set(activeDisplays())
            let newDisplays = current.subtracting(knownDisplayIDs)
            defer { knownDisplayIDs = current }

            guard !newDisplays.isEmpty else { return }
            NSLog("PowerBottom: %d new display(s) detected, arranging...", newDisplays.count)
            arrange()
        }
    }

    private func arrange() {
        let ids = activeDisplays()
        guard ids.count >= 2 else { return }

        guard let laptop = ids.first(where: { CGDisplayIsBuiltin($0) != 0 }) else {
            NSLog("PowerBottom: no built-in display found (clamshell mode?), skipping")
            return
        }
        guard let ext = ids.first(where: { CGDisplayIsBuiltin($0) == 0 }) else {
            return
        }

        let extBounds = CGDisplayBounds(ext)
        let lapBounds = CGDisplayBounds(laptop)

        var cfg: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&cfg) == .success, let c = cfg else {
            NSLog("PowerBottom: failed to begin display configuration")
            return
        }

        // Place external at origin (0,0) — this makes it the main display (menu bar + dock)
        CGConfigureDisplayOrigin(c, ext, 0, 0)

        // Place laptop centered horizontally, directly below the external
        let x = Int32((extBounds.width - lapBounds.width) / 2)
        let y = Int32(extBounds.height)
        CGConfigureDisplayOrigin(c, laptop, x, y)

        let result = CGCompleteDisplayConfiguration(c, .permanently)
        if result == .success {
            NSLog("PowerBottom: arranged external (%d) above laptop (%d) — ext: %.0fx%.0f, laptop at (%d, %d)",
                  ext, laptop, extBounds.width, extBounds.height, x, y)
        } else {
            NSLog("PowerBottom: configuration failed with error %d", result.rawValue)
        }
    }
}

// MARK: - Menu Bar App

class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let displayManager = DisplayManager()
    var enableItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        displayManager.start()

        let menu = NSMenu()
        enableItem = NSMenuItem(title: "Disable", action: #selector(toggle), keyEquivalent: "")
        enableItem.target = self
        menu.addItem(enableItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit PowerBottom", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu

        updateIcon()
    }

    @objc func toggle() {
        displayManager.enabled.toggle()
        enableItem.title = displayManager.enabled ? "Disable" : "Enable"
        updateIcon()
        NSLog("PowerBottom: %@", displayManager.enabled ? "enabled" : "disabled")
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    func updateIcon() {
        statusItem.button?.title = displayManager.enabled ? "\u{1F351}" : "\u{1F351}"
        statusItem.button?.image = nil
        // Dim the peach when disabled
        statusItem.button?.appearsDisabled = !displayManager.enabled
    }
}

// MARK: - Entry

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // no dock icon
let delegate = AppDelegate()
app.delegate = delegate
app.run()
