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
import Testing

import Crypto

@testable import ReporterCore

@Suite("Item tests") struct ItemTests {

    @Test("Test Item equality")
    func testEquality() {
        let item1 = Item(path: "foo.txt", contentModificationTime: 0, fileSize: 0, checksum: Data())
        #expect(item1 == item1)

        let item2 = Item(path: "bar.txt", contentModificationTime: 0, fileSize: 0, checksum: Data())
        #expect(item1 != item2)

        let item3 = Item(path: "foo.txt", contentModificationTime: 10, fileSize: 0, checksum: Data())
        #expect(item1 != item3)

        let item4 = Item(path: "foo.txt", contentModificationTime: 0, fileSize: 512, checksum: Data())
        #expect(item1 != item4)

        var md5 = Crypto.Insecure.MD5()
        md5.update(data: Data("hello world".utf8))
        let shasum = Data(md5.finalize())

        let item5 = Item(path: "foo.txt", contentModificationTime: 0, fileSize: 0, checksum: shasum)
        #expect(item1 != item5)
    }

}
