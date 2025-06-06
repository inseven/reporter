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

typealias Cache = [FileDetails: Data]

public class Reporter {

    static func snapshot(folderURL: URL,
                         cache: Cache,
                         console: Console) async throws -> Snapshot {

        let fileManager = FileManager.default

        // Check that we've been given a directory URL.
        guard folderURL.hasDirectoryPath else {
            throw ReporterError.notDirectory
        }

        // Check that the path exists and is a directory.
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory)
        else {
            throw ReporterError.notExists
        }
        guard isDirectory.boolValue else {
            throw ReporterError.notDirectory
        }

        // TODO: Extract this into a custom enumerator?
        // TODO: Check if I can get this directly from the enumerator?
        var files: [FileDetails] = []
        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            console.log("Failed to create enumerator")
            throw ReporterError.failed
        }
        for case let fileURL as URL in enumerator.allObjects {
            do {
                let fileAttributes = try fileURL.resourceValues(forKeys: [
                    .isRegularFileKey,
                    .fileSizeKey,
                    .contentModificationDateKey,
                    .fileSizeKey
                ])
                if fileAttributes.isRegularFile! {
                    files.append(FileDetails(
                        relativePath: try fileURL.path(relativeTo: folderURL,
                                                       percentEncoded: false),
                        contentModificationTime: fileAttributes.contentModificationDate!.timeIntervalSince1970,
                        fileSize: fileAttributes.fileSize!
                    ))
                }
            } catch {
                // TODO: Review these errors.
                console.log(error)
                console.log(fileURL)
            }
        }

        // Generate the hashes for the files concurrently.
        let items = try await withThrowingTaskGroup(of: Item.self) { group in
            let progress = Progress(totalUnitCount: Int64(files.count))
            for fileDetails in files {
                group.addTask {
                    return try await Task {
                        let url = URL(fileURLWithPath: fileDetails.relativePath,
                                      relativeTo: folderURL)
                        let checksum = try (cache[fileDetails] ?? Self.checksum(url: url))
                        let item = Item(
                            path: fileDetails.relativePath,
                            contentModificationTime: fileDetails.contentModificationTime,
                            fileSize: fileDetails.fileSize,
                            checksum: checksum
                        )
                        progress.completedUnitCount += 1
                        console.progress(progress, message: folderURL.lastPathComponent)
                        return item
                    }.value
                }
            }
            var items: [Item] = []
            for try await result in group {
                items.append(result)
            }
            return items
        }

        // Create the snapshot
        let snapshot = Snapshot(rootURL: folderURL, items: items)

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

    static func report(configuration: Configuration,
                       snapshotURL: URL,
                       console: Console) async throws -> Report {

        // Load the snapshot if it exists.
        console.log("Loading state...")
        let oldState = if FileManager.default.fileExists(atPath: snapshotURL.path) {
            try State(contentsOf: snapshotURL)
        } else {
            State()
        }

        var newState = State()

        // Iterate over the folders and index them.
        for (folder, _) in configuration.folders {

            let url = URL(fileURLWithPath: folder.expandingTildeInPath, isDirectory: true)
            console.log("Indexing '\(url.path)'...")

            let items = oldState.snapshots[url]?.items ?? []
            let cache = items.reduce(into: Cache()) { partialResult, item in
                partialResult[item.fileDetails] = item.checksum
            }

            // Get the new snapshot.
            let snapshot = try await Self.snapshot(folderURL: url,
                                                   cache: cache,
                                                   console: console)
            newState.snapshots[url] = snapshot
        }

        // Write the new state to disk.
        console.log("Saving state...")
        let encoder = BinaryEncoder()
        try encoder.encode(newState).write(to: snapshotURL)

        // Compare the snapshots for each folder.
        var folders: [KeyedChanges] = []
        for (url, snapshot) in newState.snapshots {
            console.log("Checking '\(url.path)'...")
            let oldSnapshot = oldState.snapshots[url] ?? Snapshot(rootURL: url)
            let changes = snapshot.changes(from: oldSnapshot)
            folders.append(KeyedChanges(url: url, changes: changes))
        }
        let report: Report = Report(folders: folders)

        return report
    }

    public static func run(configurationURL: URL, snapshotURL: URL) async throws {

        let console = Console()

        // Load the configuration.
        console.log("Loading configuration...")
        let configuration = try Configuration(contentsOf: configurationURL)

        // Generate the report.
        let report = try await report(configuration: configuration,
                                      snapshotURL: snapshotURL,
                                      console: console)

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

{% for change in item.changes.changes %}
    {% if change.isAddition %}
        Add {{ change.source.path }}
    {% elif change.isModification %}
        Modify {{ change.source.path }}
    {% else %}
        Delete {{ change.source.path }}
    {% endif %}
{% endfor %}

{% endfor %}
""", context: context)

        let htmlSummary = try environment.renderTemplate(string: """
<html>
    <head>
        <meta name="color-scheme" content="light dark">
        <style type="text/css">

            :root {
                --primary-background-color: #fff;
                --primary-foreground-color: #000;
                --secondary-background-color: #f6f8fa;
                --addition-background-color: #dafbe1;
                --deletion-background-color: #ffebe9;
                --modification-background-color: #c7abff;
                --border-color: #d1d9e0;
                --padding: 0.5rem;
            }

            @media (prefers-color-scheme: dark) {
                :root {
                    --primary-background-color: #181818;
                    --primary-foreground-color: #fff;
                    --secondary-background-color: #151b23;
                    --addition-background-color: #2ea04326;
                    --deletion-background-color: #f851491a;
                    --modification-background-color: #260960;
                    --border-color: #3d444d;
                }
            }

            body {
                background-color: var(--primary-background-color);
                color: var(--primary-foreground-color);
            }

            hr {
                border: 0;
                border-bottom: 1px solid var(--border-color);
            }

            footer {
                color: #aaa;
                text-align: center;
            }

            .folder {
                border: 1px solid var(--border-color);
                border-radius: 8px;
                margin-bottom: 1rem;
                overflow: hidden;
            }

            .folder header {
                background-color: var(--secondary-background-color);
                padding: calc(2 * var(--padding));
            }

            .folder header .name {
                font-weight: bold;
            }

            ul.changes {
                list-style: none;
                margin: 0;
                padding: 0;
                border-top: 1px solid var(--border-color);
            }

            ul.changes li {
                display: block;
                padding: var(--padding) calc(2 * var(--padding));
            }

            .addition {
                background-color: var(--addition-background-color);
            }

            .deletion {
                background-color: var(--deletion-background-color);
            }

            .modification {
                background-color: var(--modification-background-color);
            }

        </style>
    </head>
    <body>
        {% for item in report.folders %}
            <section class="folder">
                <header>
                    <div class="name">{{ item.name }}</div>
                </header>
                {% if item.changes.isEmpty %}{% else %}
                    <ul class="changes">
                        {% for change in item.changes.changes %}
                            {% if change.isAddition %}
                                <li class="addition">{{ change.source.path }}</li>
                            {% elif change.isModification %}
                                <li class="modification">{{ change.source.path }}</li>
                            {% else %}
                                <li class="deletion">{{ change.source.path }}</li>
                            {% endif %}
                        {% endfor %}
                    </ul>
                {% endif %}
            </section>
        {% endfor %}

        <footer>
            <p>
                Generated with <a href="https://github.com/inseven/reporter">Reporter</a> by <a href="https://jbmorley.co.uk">Jason Morley</a>.
            </p>
        </footer>

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
            from: .init(configuration.email.from),
            to: configuration.email.to.map({ Mail.User($0) }),
            subject: configuration.email.subject ?? "Change Report",
            text: summary,
            attachments: [.init(htmlContent: htmlSummary)]
        )

        console.log("Sending email...")
        try await smtp.asyncSend(mail)
        console.log("Done!")

    }

}
