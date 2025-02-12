import Foundation

#if os(Linux)

@inlinable public func autoreleasepool<Result>(invoking body: () throws -> Result) rethrows -> Result {
    return try body()
}

#endif
