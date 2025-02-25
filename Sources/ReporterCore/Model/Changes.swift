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

public struct Changes: CustomStringConvertible {

    public let additions: [Item]
    public let deletions: [Item]

    public let isEmpty: Bool

    public var description: String {
        return (
            "\(additions.count) additions\n" +
            additions
                .map { "  \($0.path)\n" }
                .joined() +
            "\(deletions.count) deletions\n" +
            deletions
                .map { "  \($0.path)\n" }
                .joined()
        )
    }

    public init(additions: [Item], deletions: [Item]) {
        self.additions = additions
                .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        self.deletions = deletions
                .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        self.isEmpty = additions.isEmpty && deletions.isEmpty
    }

}
