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

import BinaryCodable
import Crypto
import Stencil
import SwiftSMTP

public class Reporter {

    static func snapshot(path: URL, console: Console) async throws -> State.Snapshot {

        var files = [URL]()

        guard let enumerator = FileManager.default.enumerator(
            at: path,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            console.log("Failed to create enumerator")
            throw ReporterError.failed
        }

        for case let fileURL as URL in enumerator {
            do {
                let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                if fileAttributes.isRegularFile! {
                    files.append(fileURL)
                }
            } catch {
                console.log(error)
                console.log(fileURL)
            }
        }

        // Generate the hashes for the files concurrently.
        let items = try await withThrowingTaskGroup(of: State.Item.self) { group in
            let progress = Progress(totalUnitCount: Int64(files.count))
            for url in files {
                group.addTask {
                    return try await Task {
                        let item = State.Item(path: url.path, checksum: try Self.checksum(url: url))
                        progress.completedUnitCount += 1
                        console.progress(progress, message: path.lastPathComponent)
                        return item
                    }.value
                }
            }
            var items: [State.Item] = []
            for try await result in group {
                items.append(result)
            }
            return items
        }

        // Create the snapshot
        let snapshot = State.Snapshot(items: items)

        return snapshot
    }

    static func checksum(url: URL, bufferSize: Int = 4 * 1024 * 1024) throws -> Data {

        let file = try FileHandle(forReadingFrom: url)
        defer {
            file.closeFile()
        }

        var md5 = Crypto.Insecure.MD5()
        while autoreleasepool(invoking: {
                let data = file.readData(ofLength: bufferSize)
                guard data.count > 0 else {
                    return false
                }
                md5.update(data: data)
                return true
            }) {
        }

        return Data(md5.finalize())
    }

    static func report(configuration: Configuration, snapshotURL: URL, console: Console) async throws -> Report {

        // Load the snapshot if it exists.
        console.log("Loading state...")
        let oldState = if FileManager.default.fileExists(atPath: snapshotURL.path) {
            try BinaryDecoder().decode(State.self,
                                       from: try Data(contentsOf: snapshotURL))
        } else {
            State()
        }

        var newState = State()

        // Iterate over the folders and index them.
        for (folder, _) in configuration.folders {

            let url = URL(fileURLWithPath: folder.expandingTildeInPath)
            console.log("Indexing '\(url.path)'...")

            // Get the new snapshot.
            newState.snapshots[url] = try await Self.snapshot(path: url, console: console)
        }

        // Write the new state to disk.
        console.log("Saving state...")
        let encoder = BinaryEncoder()
        try encoder.encode(newState).write(to: snapshotURL)

        // Compare the snapshots for each folder.
        var report: Report = Report(folders: [])
        for (url, snapshot) in newState.snapshots {
            console.log("Checking '\(url.path)'...")
            let oldSnapshot = oldState.snapshots[url] ?? State.Snapshot()
            let changes = snapshot.changes(from: oldSnapshot)
            report.folders.append(KeyedChanges(url: url, changes: changes))
        }

        return report
    }

    public static func run(configurationURL: URL, snapshotURL: URL) async throws {

        let console = Console()

        // Load the configuration.
        console.log("Loading configuration...")
        let configuration = try Configuration(contentsOf: configurationURL)

        // Generate the report.
        let report = try await report(configuration: configuration, snapshotURL: snapshotURL, console: console)

        // Return early if there are no outstanding changes.
        if report.isEmpty {
            console.log("No changes detected; skipping report.")
            return
        }

        let environment = Environment()
        let context: [String: Any] = ["report": report]
        let summary = try environment.renderTemplate(string: """
{% for item in report.folders %}
{{ item.name }} ({{ item.path }})

{{ item.changes.additions.count }} additions
{% for addition in item.changes.additions %}{{ addition }}{% endfor %}

{{ item.changes.deletions.count }} deletions
{% for deletion in item.changes.deletions %}
{{ deletion }}
{% endfor %}

{% endfor %}
""", context: context)

        let htmlSummary = try environment.renderTemplate(string: """
<html>
    <head>
        <meta name="color-scheme" content="light dark">
        <style type="text/css">

            body {
                background-color: #fff;
                color: #000;
            }

            @media (prefers-color-scheme: dark) {
                body {
                    background-color: #181818;
                    color: #fff;
                }
            }

        </style>
    </head>
    <body>
        {% for item in report.folders %}
            <h2>{{ item.name }}</h2>
            <p>{{ item.path }}</p>
            {% if item.changes.isEmpty %}
                <p>No changes.</p>
            {% else %}
                <ul>
                    <li>
                        {{ item.changes.additions.count }} additions
                        <ul>
                            {% for addition in item.changes.additions %}
                                <li>{{ addition }}</li>
                            {% endfor %}
                        </ul>
                    </li>
                    <li>
                        {{ item.changes.deletions.count }} deletions
                        <ul>
                            {% for deletion in item.changes.deletions %}
                                <li>{{ deletion }}</li>
                            {% endfor %}
                        </ul>
                    </li>
                </ul>
            {% endif %}
        {% endfor %}

        <hr />

        <p>
            Generated with <a href="https://github.com/inseven/reporter">Reporter</a> by <a href="https://jbmorley.co.uk">Jason Morley</a>.
        </p>
    </body>
</html>
""", context: context)

        // Send a summary email.
        let smtp = SMTP(
            hostname: configuration.mailServer.host,
            email: configuration.mailServer.username,
            password: configuration.mailServer.password,
            port: configuration.mailServer.port,
            tlsMode: .requireSTARTTLS,
            tlsConfiguration: nil,
            authMethods: [],
            domainName: configuration.mailServer.domain,
            timeout: configuration.mailServer.timeout ?? 60
        )

        let mail = Mail(
            from: .init(email: configuration.mailServer.from),
            to: [.init(email: configuration.mailServer.to)],
            subject: "Change Report",
            text: summary,
            attachments: [.init(htmlContent: htmlSummary)]
        )

        console.log("Sending email...")
        try await smtp.asyncSend(mail)
        console.log("Done!")

    }

}
