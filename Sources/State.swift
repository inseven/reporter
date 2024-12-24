import Foundation

struct State: Codable, CustomStringConvertible {

    struct Item: Codable, Hashable {
        let path: String
    }

    struct Snapshot: Codable {

        var description: String {
            return "\(items.count) files"
        }

        let items: Set<Item>

        init(items: [Item] = []) {
            self.items = Set(items)
        }

        func changes(from initialState: Snapshot) -> Changes {
            let additions = items.subtracting(initialState.items)
            let deletions = initialState.items.subtracting(items)
            return Changes(
                additions: Set(additions.map { $0.path }),
                deletions: Set(deletions.map { $0.path })
            )
        }

    }

    var snapshots: [URL: Snapshot]

    var description: String {
        return "State Description"
    }

    init() {
        self.snapshots = [:]
    }

}