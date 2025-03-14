//
//  Linker.swift
//  Takeover
//
//  Created by Alex Vaos on 2/27/25.
//

import Foundation

class Linker {
    static func link(from: String, to: String) {
        shell("ln -s \(from) \(to)")
    }
    
    static func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        return String(data: data, encoding: .utf8)!
    }
}


/*
 #!/usr/bin/env sh

 # Create Link
 # Create a link at the source to the destination

 if [[ -z $1 ]]; then
   cat << EOF
 Create Link
   Move source to destination and create sym link from source to destination
   If destination exists, add date to the old destination
 usage:
   create_link [source] [destination]
 EOF
   exit 0
 fi

 S="$1"
 D="$2"

 # Duplicate Directory
 [[ -n $3 ]] && DD="$3" || DD="$D"-old-`date "+%Y-%m-%d"`

 # Remove If Link
 [[ -L "$S" ]] && rm -rf "$S"
 [[ -L "$D" ]] && rm -rf "$D"

 # Make Dir
 mkdir -p "`dirname "$D"`"

 # Rename Files if Exist
 if [[ -e "$S" ]]; then # If source exists
   if [[ -e "$D" ]]; then # If destination exists
     mv "$S" "$DD" # Move to duplicate
   else
     mv "$S" "$D"
   fi
 else # source does nto exist
   if [[ ! -e "$D" ]]; then
     echo "Neither of locations exist"
     echo "Source: $S"
     echo "Destination: $D"
     exit 0
   fi
 fi

 # Create Links
 ln -s "$D" "$S"
 printf "Created Link\n  From: $S\n  To: $D"

 */
