import Foundation

import SwiftSMTP

extension SMTP {

    func asyncSend(_ mail: Mail) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) -> Void in
            send(mail) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

}