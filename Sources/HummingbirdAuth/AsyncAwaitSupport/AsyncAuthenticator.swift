//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2021-2021 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if compiler(>=5.5) && canImport(_Concurrency)

import Hummingbird
import NIOCore

/// Async version of Middleware to check if a request is authenticated and then augment the request with
/// authentication data.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol HBAsyncAuthenticator: HBAuthenticator {
    associatedtype Value = Value
    func authenticate(request: HBRequest) async throws -> Value?
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension HBAsyncAuthenticator {
    public func authenticate(request: HBRequest) -> EventLoopFuture<Value?> {
        let promise = request.eventLoop.makePromise(of: Value?.self)
        promise.completeWithTask {
            try await authenticate(request: request)
        }
        return promise.futureResult
    }
}

#endif // compiler(>=5.5) && canImport(_Concurrency)
