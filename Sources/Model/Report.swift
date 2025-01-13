import Foundation

struct Report {

    var isEmpty: Bool {
        return folders.reduce(true) { partialResult, folder in
            return partialResult && folder.changes.isEmpty
        }
    }

    var folders: [KeyedChanges]

}
