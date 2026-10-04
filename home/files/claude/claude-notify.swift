// claude-notify <title> <body>: posts one macOS notification, which shows the icon of the app bundle this runs from.
// See docs/design/claude-tmux-state.md
import Foundation
import UserNotifications

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("claude-notify: \(message)\n".utf8))
  exit(1)
}

let args = CommandLine.arguments
guard args.count == 3 else { exit(64) } // clicking a banner relaunches the app with no arguments

let center = UNUserNotificationCenter.current()
center.requestAuthorization(options: [.alert]) { granted, _ in
  guard granted else { fail("notifications are off for Claude Code in System Settings") }
  let content = UNMutableNotificationContent()
  content.title = args[1]
  content.body = args[2]
  center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)) { error in
    if let error { fail(error.localizedDescription) }
    exit(0)
  }
}
dispatchMain()
