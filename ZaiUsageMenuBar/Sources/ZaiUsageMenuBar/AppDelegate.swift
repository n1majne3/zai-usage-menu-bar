import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    static var shared: AppDelegate?

    var statusItem: NSStatusItem!
    var popover = NSPopover()
    var refreshTimer: Timer?
    private var globalDismissMonitor: Any?
    private var localKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "--"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let contentView = MenuBarContentView()
        popover.contentSize = NSSize(width: 300, height: 360)
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.delegate = self

        refreshTimer = Timer(timeInterval: 300, repeats: true) { _ in
            NotificationCenter.default.post(name: .refreshUsage, object: nil)
        }
        RunLoop.main.add(refreshTimer!, forMode: .common)
    }

    func updateStatusItem(percentage: Double?) {
        guard let button = statusItem.button else { return }
        if let percentage = percentage {
            button.title = String(format: "%.0f%%", percentage)
        } else {
            button.title = "--"
        }
    }

    @objc func statusItemClicked(_ sender: AnyObject?) {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            hidePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    func showPopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // LSUIElement app is never active on its own; without activation the
        // popover can't become key and .transient dismissal is dead on macOS 26.
        // Plain NSApp.activate() is a no-op without a prior user interaction, so
        // force it through NSRunningApplication (plan risk #1 fallback).
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
        popover.contentViewController?.view.window?.makeKey()
        installDismissMonitors()
    }

    func hidePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }

    private var popoverHasAttachedSheet: Bool {
        popover.contentViewController?.view.window?.attachedSheet != nil
    }

    // Consulted by both performClose and AppKit's transient dismissal.
    // While the settings sheet is up, the popover must behave like a modal
    // host; closing it would orphan the sheet and wedge the panel.
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return !popoverHasAttachedSheet
    }

    // Single teardown path for every way the popover closes (button, transient,
    // monitor, resign-active).
    func popoverDidClose(_ notification: Notification) {
        removeDismissMonitors()
        // Heal any presentation state that would otherwise survive the close
        // (e.g. the settings sheet) and wedge the next show.
        NotificationCenter.default.post(name: .popoverDidCloseNotification, object: nil)
    }

    func applicationDidResignActive(_ notification: Notification) {
        if popover.isShown && !popoverHasAttachedSheet {
            hidePopover(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !popover.isShown {
            showPopover(nil)
        }
        return false
    }

    private func installDismissMonitors() {
        removeDismissMonitors()
        globalDismissMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.popover.isShown, !self.popoverHasAttachedSheet else { return }
            // A click on our own status item must keep its toggle semantics;
            // on macOS 26 status items are hosted out-of-process, so it may
            // surface here as a "global" event.
            if let window = self.statusItem.button?.window,
               NSMouseInRect(NSEvent.mouseLocation, window.frame, false) {
                return
            }
            self.hidePopover(nil)
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.popover.isShown, event.keyCode == 53,
                  !self.popoverHasAttachedSheet else { return event }
            self.hidePopover(nil)
            return nil
        }
    }

    private func removeDismissMonitors() {
        if let monitor = globalDismissMonitor {
            NSEvent.removeMonitor(monitor)
            globalDismissMonitor = nil
        }
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }

    private func showContextMenu() {
        if popover.isShown {
            hidePopover(nil)
        }
        let menu = NSMenu()
        let quitItem = NSMenuItem(title: L10n.localized("quit"), action: #selector(quitApp(_:)), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func quitApp(_ sender: AnyObject?) {
        NSApp.terminate(nil)
    }
}

extension Notification.Name {
    static let refreshUsage = Notification.Name("refreshUsage")
    static let popoverDidCloseNotification = Notification.Name("popoverDidCloseNotification")
}
