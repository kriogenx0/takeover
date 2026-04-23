import Foundation

struct MacDefaultInstaller {

    @discardableResult
    @MainActor
    static func capture(macDefault: MacDefault) -> String {
        let result = Linker.shell("defaults read \(macDefault.domain) \(macDefault.key)")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let notFound = result.isEmpty
            || result.contains("does not exist")
            || result.contains("The domain/defaults pair")
        if !notFound { macDefault.value = result }
        return notFound ? "" : result
    }

    @MainActor
    static func apply(macDefault: MacDefault) {
        guard !macDefault.value.isEmpty else { return }
        let result = Linker.shell(macDefault.writeCommand)
        print("Apply defaults result: \(result)")
        if !macDefault.postCommand.isEmpty {
            let postResult = Linker.shell(macDefault.postCommand)
            print("Post command result: \(postResult)")
        }
    }

    @MainActor
    static func captureAll(_ items: [MacDefault]) {
        for item in items { capture(macDefault: item) }
    }

    @MainActor
    static func applyAll(_ items: [MacDefault]) {
        for item in items { apply(macDefault: item) }
    }
}
