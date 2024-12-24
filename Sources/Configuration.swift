import Foundation

struct Configuration: Codable {

    struct Server: Codable {

        let host: String
        let port: Int32
        let username: String
        let password: String

        let domain: String
        let timeout: UInt?

        let from: String
        let to: String

    }

    struct Policy: Codable {

    }

    let mailServer: Server
    let folders: [String: Policy]

}
