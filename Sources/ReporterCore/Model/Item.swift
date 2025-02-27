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

public struct Item: Codable, Hashable, Sendable {

    enum CodingKeys: String, CodingKey {
        case path
        case contentModificationTime
        case fileSize
        case checksum
    }

    public let path: String
    public let contentModificationTime: TimeInterval
    public let fileSize: Int

    public var fileDetails: FileDetails {
        return FileDetails(relativePath: path,
                           contentModificationTime: contentModificationTime,
                           fileSize: fileSize)
    }
    
    public let checksum: Data?

    public init(path: String,
                contentModificationTime: TimeInterval,
                fileSize: Int,
                checksum: Data?) {
        self.path = path
        self.contentModificationTime = contentModificationTime
        self.fileSize = fileSize
        self.checksum = checksum
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.path = try container.decode(String.self, forKey: CodingKeys.path)
        let data = try container.decode(Data.self,
                                        forKey: CodingKeys.contentModificationTime)
        self.contentModificationTime = TimeInterval(data)
        self.fileSize = try container.decode(Int.self, forKey: CodingKeys.fileSize)
        self.checksum = try container.decode(Data.self, forKey: CodingKeys.checksum)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // We round-trip the TimeInterval (aka Double) through Data to ensure there's an
        // extra copy which avoids a misaligned read.
        try container.encode(contentModificationTime.data,
                             forKey: CodingKeys.contentModificationTime)
        try container.encode(path, forKey: CodingKeys.path)
        try container.encode(fileSize, forKey: CodingKeys.fileSize)
        try container.encode(checksum, forKey: CodingKeys.checksum)
    }

}

// https://stackoverflow.com/questions/43241845/how-can-i-convert-data-into-types-like-doubles-ints-and-strings-in-swift#43244973

extension DataProtocol where Self: RangeReplaceableCollection {
    init<N: Numeric>(_ numeric: N) {
        self = withUnsafeBytes(of: numeric) { .init($0) }
    }
}

extension Numeric {
    var data: Data { .init(self) }
    var bytes: [UInt8] { .init(self) }
}

extension Numeric {
    init<D: DataProtocol>(_ data: D) {
        var value: Self = .zero
        _ = withUnsafeMutableBytes(of: &value, data.copyBytes)
        self = value
    }
}

extension DataProtocol {
    func value<N: Numeric>() -> N { .init(self) }
}
