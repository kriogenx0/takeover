import Darwin
import Foundation

// MARK: - Entry point

let terminal = RawTerminal()

// Restore terminal on Ctrl-C
signal(SIGINT) { _ in
    var t = termios()
    tcgetattr(STDIN_FILENO, &t)
    t.c_lflag |= tcflag_t(ICANON | ECHO)
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &t)
    print("\u{001B}[?25h", terminator: "")  // show cursor
    fflush(stdout)
    exit(0)
}

do {
    let links = try loadSettings()

    if links.isEmpty {
        print("No links configured in \(Config.settingsPath)")
        print("Add entries to your takeover-settings.yaml file.")
        exit(0)
    }

    terminal.enable()
    defer { terminal.disable() }

    var menu = Menu(terminal: terminal, links: links)
    menu.run()

} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}
