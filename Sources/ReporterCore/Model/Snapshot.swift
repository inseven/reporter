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

public struct Snapshot: Codable {

    public var description: String {
        return "\(items.count) files"
    }

    public let rootURL: URL
    public let items: Set<Item>

    public init(rootURL: URL, items: [Item] = []) {
        self.rootURL = rootURL
        self.items = Set(items)
    }

    public func changes(from initialState: Snapshot) -> Changes {
        let additions = items.subtracting(initialState.items)
            .map { Change(kind: .addition, source: $0) }
        let deletions = initialState.items.subtracting(items)
            .map { Change(kind: .deletion, source: $0) }
        return Changes(changes: Array(additions) + Array(deletions))
    }

}
