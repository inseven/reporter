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

        // Determining the type of change is a little nuanced and there are many different ways to do this.
        // This approach builds a mutable lookup of the files in the initial state and then walks all of the new files
        // and determines a possible change that occurred (addition, or modification). We track all the seen files
        // to allow us to subtract these from our initial set to find deleted files.

        let initialItemsByPath = initialState.items.reduce(into: [String: Item]()) { $0[$1.path] = $1 }

        var additions: [Change] = []
        var modifications: [Change] = []
        var seen: Set<Item> = []  // Tracking items that we've seen and attributed a change to.

        // Check for unchanged files and modifications.
        for item in items {
            if let initialItem = initialItemsByPath[item.path] {
                // The path exists in the initial state, so it's either unchanged, or represents a content modification.
                if initialItem != item {
                    modifications.append(Change(kind: .modification, source: initialItem, destination: item))
                }
                seen.insert(initialItem)
            } else {
                additions.append(Change(kind: .addition, source: item))
            }
        }

        // Anything that was not attributed to an extant file or a modification.
        let deletions = initialState.items.subtracting(seen)
            .map { Change(kind: .deletion, source: $0) }

        return Changes(changes: Array(additions) + Array(deletions) + Array(modifications))
    }

}
