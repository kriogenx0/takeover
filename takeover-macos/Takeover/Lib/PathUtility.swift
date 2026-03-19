//
//  PathUtility.swift
//  Takeover
//
//  Created by Alex Vaos on 2/12/25.
//

import Foundation

struct PathUtility {
    /// Expands ~ to the real user home directory (not sandboxed)
    static func expandTildeToRealHome(_ path: String) -> String {
        if path.hasPrefix("~") {
            let realHomeDir = getRealHomeDirectory()
            return path.replacingOccurrences(of: "~", with: realHomeDir, options: .anchored)
        }
        return path
    }

    /// Gets the real user home directory using getpwuid (not sandboxed)
    static func getRealHomeDirectory() -> String {
        let pw = getpwuid(getuid())
        if let homeDir = pw?.pointee.pw_dir {
            return String(cString: homeDir)
        }
        // Fallback to /Users/<username> if getpwuid fails
        return "/Users/\(NSUserName())"
    }
}
