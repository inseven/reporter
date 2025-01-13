import Foundation

struct Changes: CustomStringConvertible {

    let additions: [String]
    let deletions: [String]

    var description: String {
        return (
            "\(additions.count) additions\n" +
            additions
                .sorted()
                .map { "  \($0)\n" }
                .joined() +
            "\(deletions.count) deletions\n" +
            deletions
                .sorted()
                .map { "  \($0)\n" }
                .joined()
        )
    }

    var isEmpty: Bool {
        return additions.isEmpty && deletions.isEmpty
    }

}