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
import ArgumentParser

import ReporterCore

import Crypto

func exampleChecksum(data: Data) throws -> Data {
    var md5 = Crypto.Insecure.MD5()
    if data.count > 0 {
        md5.update(data: data)
    }
    return Data(md5.finalize())
}

extension Item {

    init(exampleWithSubPath subPath: String, contents: String) throws {

        guard let data = contents.data(using: .utf8) else {
            throw ReporterError.failed
        }
        self.init(path: subPath,
                  contentModificationTime: Date.now.timeIntervalSince1970,
                  fileSize: data.count,
                  checksum: try exampleChecksum(data: data))
    }

}

struct CommandSendTestEmail: AsyncParsableCommand {

    @Argument(transform: URL.init(fileURLWithPath:))
    var config: URL?

    public static let configuration = CommandConfiguration(
        commandName: "send-test-email",
        abstract: "Send a test email.")

    mutating func run() async throws {
        let configuration = try Configuration(contentsOf: config ?? .configURL)
        let report = Report(folders: [
            KeyedChanges(url: URL(fileURLWithPath: "/Users/home/jbmorley/Documents"), changes: Changes(changes: [
                Change(additionWithSource: try Item(exampleWithSubPath: "Example.txt",
                                                    contents: "Hello, World.")),
                Change(deletionWithSource: try Item(exampleWithSubPath: "Screenshot.png",
                                                    contents: "This is an image, honest.")),
                Change(modificationWithSource: try Item(exampleWithSubPath: "Report.csv",
                                                        contents: "1,2,3"),
                       destination: try Item(exampleWithSubPath: "Report.csv", contents: "1,2,3,4,5,6")),
            ]))
        ])
        let mailer = Mailer(configuration: configuration)
        try await mailer.send(report: report)
    }

}
