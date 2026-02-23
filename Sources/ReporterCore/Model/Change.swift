// Copyright (c) 2024-2026 Jason Morley
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

public struct Change: Equatable {

    enum Kind {
        case addition
        case deletion
        case modification
    }

    let kind: Kind
    let source: Item
    let destination: Item?

    // Stencil doesn't support computed properties so we evaluate these on construction.
    let isAddition: Bool
    let isDeletion: Bool
    let isModification: Bool

    // TODO: Rename `source` and `destination` as they're misleading in the case of a modification? `old` and `new`?
    init(kind: Kind, source: Item, destination: Item? = nil) {
        self.kind = kind
        self.source = source
        self.destination = destination
        
        self.isAddition = kind == .addition
        self.isDeletion = kind == .deletion
        self.isModification = kind == .modification
    }

}
