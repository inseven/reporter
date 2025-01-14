import Foundation

extension String {

    var expandingTildeInPath: String {
        return (self as NSString).expandingTildeInPath
    }

}
