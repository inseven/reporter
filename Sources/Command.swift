import Foundation

import ArgumentParser
import BinaryCodable
import Stencil
import SwiftSMTP

enum ReporterError: Error {
    case failed
}

@main
struct Command: AsyncParsableCommand {

    @Argument(transform: URL.init(fileURLWithPath:))
    var config: URL?

    @Argument(transform: URL.init(fileURLWithPath:))
    var snapshot: URL?

    func snapshot(for path: URL) async throws -> State.Snapshot {

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

        // Create the snapshot
        let snapshot = State.Snapshot(items: files.map { url in
            return State.Item(path: url.path)
        })

        return snapshot
    }

    mutating func run() async throws {
        let fileManager = FileManager.default

        // Load the configuration
        print("Loading configuration...")
        let data = try Data(contentsOf: config ?? .configURL)
        let decoder = JSONDecoder()
        let configuration = try decoder.decode(Configuration.self, from: data)

        let snapshotURL = snapshot ?? .snapshotURL

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

            let url = URL(fileURLWithPath: (folder as NSString).expandingTildeInPath)
            print("Indexing \(url)...")

            // Get the new snapshot.
            newState.snapshots[url] = try await snapshot(for: url)
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
            report.folders.append(KeyedChanges(name: url.path, url: url, changes: changes))
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
{{ item.name }}

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
    <ul>
        {% for item in report.folders %}
            <li>
                <strong>{{ item.name }}</strong>
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
            </li>
        {% endfor %}
    </ul>
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
            subject: "Syncthing Change Summary",
            text: summary,
            attachments: [.init(htmlContent: htmlSummary)]
        )

        print("Sending email...")
        try await smtp.asyncSend(mail)
        print("Done!")

    }

}
