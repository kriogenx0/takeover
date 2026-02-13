//
//  Config.swift
//  Takeover
//
//  Created by Alex Vaos on 2/12/25.
//

import Foundation

struct Config {
    /// The backup path where Takeover stores its backups
    static let backupPath = "~/Library/Application Support/Takeover"

    /// Returns the expanded backup path (with ~ resolved to real home directory)
    static var expandedBackupPath: String {
        return PathUtility.expandTildeToRealHome(backupPath)
    }
}
