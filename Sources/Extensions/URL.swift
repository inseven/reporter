import Foundation

extension URL {

    static let configURL = URL(fileURLWithPath: "~/.config/reporter/config.json".expandingTildeInPath)
    static let snapshotURL = URL(fileURLWithPath: "~/.config/reporter/snapshot".expandingTildeInPath)

}
