//
//  Reporter.swift
//  reporter
//
//  Created by Jason Barrie Morley on 13/02/2025.
//

import Foundation

import BinaryCodable
import Crypto
import Stencil
import SwiftSMTP

import ReporterCore

class Reporter {

    static func snapshot(for path: URL) async throws -> State.Snapshot {

        var files = [URL]()

        guard let enumerator = FileManager.default.enumerator(
            at: path,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            print("Failed to create enumerator")
            throw ReporterError.failed
        }

        for case let fileURL as URL in enumerator {
            do {
                let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                if fileAttributes.isRegularFile! {
                    files.append(fileURL)
                }
            } catch {
                print(error, fileURL)
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
                        if Shell.isInteractive {
                            let percentage = Int(progress.fractionCompleted * 100)
                            print("\(path.lastPathComponent): \(percentage)% (\(progress.completedUnitCount) / \(progress.totalUnitCount))")
                        }
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

    static func run(configurationURL: URL, snapshotURL: URL) async throws {
        let fileManager = FileManager.default

        // Load the configuration
        print("Loading configuration...")
        let data = try Data(contentsOf: configurationURL)
        let decoder = JSONDecoder()
        let configuration = try decoder.decode(Configuration.self, from: data)

        // Load the snapshot if it exists.
        print("Loading state...")
        let oldState = if fileManager.fileExists(atPath: snapshotURL.path) {
            try BinaryDecoder().decode(State.self,
                                       from: try Data(contentsOf: snapshotURL))
        } else {
            State()
        }

        var newState = State()

        // Iterate over the folders and index them.
        for (folder, _) in configuration.folders {

            let url = URL(fileURLWithPath: folder.expandingTildeInPath)
            print("Indexing \(url)...")

            // Get the new snapshot.
            newState.snapshots[url] = try await Self.snapshot(for: url)
        }

        // Write the new state to disk.
        print("Saving state...")
        let encoder = BinaryEncoder()
        try encoder.encode(newState).write(to: snapshotURL)

        // Compare the snapshots for each folder.
        var report: Report = Report(folders: [])
        for (url, snapshot) in newState.snapshots {
            print("Checking \(url)...")
            let oldSnapshot = oldState.snapshots[url] ?? State.Snapshot()
            let changes = snapshot.changes(from: oldSnapshot)
            report.folders.append(KeyedChanges(url: url, changes: changes))
        }

        // Return early if there are no outstanding changes.
        if report.isEmpty {
            print("No changes detected; skipping report.")
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
        Generated using <a href="https://github.com/inseven/reporter">Reporter</a>.
    </p>
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

        print("Sending email...")
        try await smtp.asyncSend(mail)
        print("Done!")

    }

}
