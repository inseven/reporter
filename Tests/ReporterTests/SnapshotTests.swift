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

import Testing
import Foundation

@testable import ReporterCore

@Suite("Snapshot tests") struct SnapshotTests {

    @Test("Test empty snapshot comparison with no changes")
    func testEmtpy() {
        let root = URL(filePath: "/home/jbmorley/Files")
        let snapshot1 = Snapshot(rootURL: root)
        let snapshot2 = Snapshot(rootURL: root)
        let changes = snapshot1.changes(from: snapshot2)
        #expect(changes.isEmpty)
    }

    @Test("Test non-empty snapshot comparison with no changes")
    func testNonEmtpy() {
        let root = URL(filePath: "/home/jbmorley/Files")
        let item = Item(path: "foo.txt", contentModificationTime: 0)
        let snapshot1 = Snapshot(rootURL: root, items: [item])
        let snapshot2 = Snapshot(rootURL: root, items: [item])
        let changes = snapshot1.changes(from: snapshot2)
        #expect(changes.isEmpty)
    }

    @Test("Test snapshot comparison with a single addition")
    func testSingleAddition() {
        let root = URL(filePath: "/home/jbmorley/Files")
        let item = Item(path: "foo.txt", contentModificationTime: 0)
        let snapshot1 = Snapshot(rootURL: root)
        let snapshot2 = Snapshot(rootURL: root, items: [item])
        let changes = snapshot2.changes(from: snapshot1)
        #expect(changes == Changes(changes: [
            Change(kind: .addition, source: item)
        ]))
    }

    @Test("Test snapshot comparison with a single deletion")
    func testSingleDeletion() {
        let root = URL(filePath: "/home/jbmorley/Files")
        let item = Item(path: "foo.txt", contentModificationTime: 0)
        let snapshot1 = Snapshot(rootURL: root, items: [item])
        let snapshot2 = Snapshot(rootURL: root)
        let changes = snapshot2.changes(from: snapshot1)
        #expect(changes == Changes(changes: [
            Change(kind: .deletion, source: item)
        ]))
    }

    @Test("Test snapshot comparison with a single addition and deletion")
    func testAdditionAndDeletion() {
        let root = URL(filePath: "/home/jbmorley/Files")
        let item1 = Item(path: "foo.txt", contentModificationTime: 0)
        let item2 = Item(path: "bar.txt", contentModificationTime: 0)
        let snapshot1 = Snapshot(rootURL: root, items: [item1])
        let snapshot2 = Snapshot(rootURL: root, items: [item2])
        let changes = snapshot2.changes(from: snapshot1)
        #expect(changes == Changes(changes: [
            Change(kind: .deletion, source: item1),
            Change(kind: .addition, source: item2)
        ]))
    }

    @Test("Test snapshot comparison with a single modification")
    func testSingleModification() {
        let root = URL(filePath: "/home/jbmorley/Files")
        let item1 = Item(path: "foo.txt", contentModificationTime: 0, contents: "Hello")
        let item2 = Item(path: "foo.txt", contentModificationTime: 0, contents: "Goodbye")
        let snapshot1 = Snapshot(rootURL: root, items: [item1])
        let snapshot2 = Snapshot(rootURL: root, items: [item2])
        let changes = snapshot2.changes(from: snapshot1)
        #expect(changes == Changes(changes: [
            Change(kind: .modification, source: item1, destination: item2)
        ]))
    }

}
