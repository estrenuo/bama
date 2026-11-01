import AppKit
import IOKit.pwr_mgt
import SwiftData
import __APP_NAME__Kit

/// Self-test for agents: runs the app's real functions on a test store,
/// prints PASS or FAIL per check, and quits with exit code 0 or 1.
///   APP_STORE=/tmp/__APP_NAME__-self.store ~/Applications/__APP_NAME__.app/Contents/MacOS/__APP_NAME__ --selftest
/// (tools/selftest.sh does this.) Add a check for every story with logic.
/// Checks live in groups, one file per group once it grows
/// (`SelfTest+Search.swift` with `checkSearch`), listed in `groups`.
/// `tools/selftest.sh search` runs one group for quick feedback.
@MainActor
enum SelfTest {
    static var requested: Bool { CommandLine.arguments.contains("--selftest") }
    /// Read by AppDelegate.applicationWillTerminate.
    static var exitCode: Int32 = 0
    private static var failures = 0
    private static var count = 0
    /// Keeps the display awake: with it asleep no window can take the keyboard.
    private static var awake: NSObjectProtocol?

    /// The check groups in run order, by the short name APP_SELFTEST_ONLY takes.
    static let groups: [(name: String, run: @MainActor (AppModel) async -> Void)] = [
        ("basics", { await checkBasics(model: $0) }),
    ]

    static func runIfRequested(model: AppModel) {
        guard requested else { return }
        // Print each line at once, so a crash keeps the lines before it.
        setvbuf(stdout, nil, _IOLBF, 0)
        guard Store.isOverridden else {
            print("SELFTEST refused: set APP_STORE to a file in /tmp")
            finish(code: 1)
            return
        }
        let only = groupsAsked()
        if let only, let unknown = only.first(where: { name in !groups.contains { $0.name == name } }) {
            print("SELFTEST refused: no group “\(unknown)”. Groups: \(groups.map(\.name).joined(separator: ", "))")
            finish(code: 1)
            return
        }
        // A sleeping display or a locked screen fails every focus check.
        awake = ProcessInfo.processInfo.beginActivity(options: [.idleDisplaySleepDisabled, .userInitiated],
                                                      reason: "Self-test needs a window with the keyboard")
        if CGDisplayIsAsleep(CGMainDisplayID()) != 0 {
            // Wakes the display, as a key press would; it cannot unlock the screen.
            var id = IOPMAssertionID(0)
            _ = IOPMAssertionDeclareUserActivity("__APP_NAME__ self-test" as CFString, kIOPMUserActiveLocal, &id)
        }
        var blockers: Set<String> = []
        if screenIsLocked { blockers.insert("the screen was locked") }
        let center = NSWorkspace.shared.notificationCenter
        let sleeps = [(NSWorkspace.screensDidSleepNotification, "the display slept"),
                      (NSWorkspace.sessionDidResignActiveNotification, "the screen was locked")].map { name, reason in
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { _ = blockers.insert(reason) }
            }
        }
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            // Name every app that comes to the front, so a failure caused by
            // someone using the Mac is easy to tell apart from a bug.
            var intruders: Set<String> = []
            let watch = center.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                                           object: nil, queue: .main) { note in
                let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                if let app, app != .current { MainActor.assumeIsolated { _ = intruders.insert(app.localizedName ?? "?") } }
            }
            for group in groups where only?.contains(group.name) ?? true {
                await group.run(model)
            }
            center.removeObserver(watch)
            sleeps.forEach(center.removeObserver)
            if screenIsLocked { blockers.insert("the screen was locked") }
            if failures > 0, !blockers.isEmpty {
                print("NOTE during the run \(blockers.sorted().joined(separator: " and ")). "
                      + "Focus checks fail then; run again with the Mac awake and unlocked.")
            }
            if failures > 0, !intruders.isEmpty {
                print("NOTE \(intruders.sorted().joined(separator: ", ")) came to the front during the run. "
                      + "Focus checks fail then; run again without using the Mac.")
            }
            let ran = only.map { $0.joined(separator: ", ") } ?? "all groups"
            print(failures == 0 ? "SELFTEST PASS \(count) checks (\(ran))" : "SELFTEST FAIL \(failures) of \(count) checks (\(ran))")
            finish(code: failures == 0 ? 0 : 1)
        }
    }

    /// The group names in APP_SELFTEST_ONLY, lowercased; nil runs every group.
    private static func groupsAsked() -> [String]? {
        let names = (ProcessInfo.processInfo.environment["APP_SELFTEST_ONLY"] ?? "")
            .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
        return names.isEmpty ? nil : names
    }

    /// True while the login window covers the screen.
    private static var screenIsLocked: Bool {
        (CGSessionCopyCurrentDictionary() as? [String: Any])?["CGSSessionScreenIsLocked"] as? Bool == true
    }

    private static func checkBasics(model: AppModel) async {
        let context = model.container.mainContext
        func items() -> [Item] { (try? context.fetch(FetchDescriptor<Item>())) ?? [] }

        let before = items().count
        model.addItem()
        check("New Item adds one item", items().count == before + 1)
        check("the new item is selected", model.selection != nil)

        if let item = items().first(where: { $0.id == model.selection }) {
            item.isStarred.toggle()
            check("starring an item marks it starred", item.isStarred)
            context.delete(item)
            try? context.save()
            check("deleting the item removes it", items().count == before)
        }
        check("titles are cleaned", ItemTitle.clean("  Buy   milk ") == "Buy milk")
    }

    static func check(_ name: String, _ ok: Bool, _ detail: String = "") {
        count += 1
        if !ok { failures += 1 }
        print(ok ? "PASS \(name)" : "FAIL \(name)\(detail.isEmpty ? "" : ": \(detail)")")
    }

    /// Quits through NSApp.terminate, never exit(), and closes sheets first:
    /// an open sheet refuses terminate, and the run would wait forever.
    static func finish(code: Int32) {
        exitCode = code
        for window in NSApp.windows { if let sheet = window.attachedSheet { window.endSheet(sheet) } }
        NSApp.terminate(nil)
    }
}
