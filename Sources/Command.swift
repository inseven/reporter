import Foundation

import ArgumentParser
import BinaryCodable
import Stencil
import SwiftSMTP

enum ReporterError: Error {
    case failed
}

struct KeyedChanges {
    let url: URL
    let changes: Changes
}

@main
struct Command: AsyncParsableCommand {

    @Argument(transform: URL.init(fileURLWithPath:))
    var config: URL

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
        let data = try Data(contentsOf: config)
        let decoder = JSONDecoder()
        let configuration = try decoder.decode(Configuration.self, from: data)

        let snapshotURL = URL(fileURLWithPath: "snapshot")

        // Load the snapshot if it exists.
        print("Loading state...")
        let oldState = if fileManager.fileExists(atPath: snapshotURL.path) {
            try BinaryDecoder().decode(State.self,
                                       from: try Data(contentsOf: snapshotURL))
        } else {
            State()
        }
        print(oldState.description)

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
        var report: [KeyedChanges] = []
        for (url, snapshot) in newState.snapshots {
            print("Checking \(url)...")
            let oldSnapshot = oldState.snapshots[url] ?? State.Snapshot()
            let changes = snapshot.changes(from: oldSnapshot)
            report.append(KeyedChanges(url: url, changes: changes))
        }

        // let summary = report.map { (url, changes) in
        //     return url.path + "\n" + String(repeating: "-", count: url.path.count) + "\n\n" + String(describing: changes)
        // }.joined(separator: "\n")


        let environment = Environment()
        let context: [String: Any] = ["name": "kyle", "report": report]
        let summary = try environment.renderTemplate(string: """
{% for item in report %}
{{ item.url.path }}

{{ item.changes.additions.count }} additions
{% for addition in item.changes.additions %}{{ addition }}{% endfor %}

{{ item.changes.deletions.count }} deletions
{% for deletion in item.changes.deletions %}
{{ deletion }}
{% endfor %}

{% endfor %}
""", context: context)

        print(summary)

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
            text: summary
        )

        print("Sending email...")
        try await smtp.asyncSend(mail)
        print("Done!")

    }

}
