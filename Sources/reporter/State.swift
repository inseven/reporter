// Copyright (c) 2024-2025 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

struct State: Codable {

    struct Item: Codable, Hashable {
        let path: String
        let checksum: Data?
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
                additions: additions.map { $0.path },
                deletions: deletions.map { $0.path }
            )
        }

    }

    var snapshots: [URL: Snapshot]

    init() {
        self.snapshots = [:]
    }

}
