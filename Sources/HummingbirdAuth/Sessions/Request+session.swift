//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2021-2022 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Hummingbird
import HummingbirdFoundation

/// Manage session ids and associated data
public struct SessionManager: Sendable {
    /// SessionManager Errors
    public struct Error: Swift.Error, Equatable {
        enum ErrorType {
            case sessionDoesNotExist
        }

        let type: ErrorType
        private init(_ type: ErrorType) {
            self.type = type
        }

        /// Session does not exist
        public static var sessionDoesNotExist: Self { .init(.sessionDoesNotExist) }
    }

    // typealias for SessionIDStorage
    public typealias SessionIDStorage = HBSessionStorage.SessionIDStorage

    internal static var sessionID: SessionIDStorage = .cookie("SESSION_ID")

    /// Initialize SessionManager from request
    init(request: HBRequest) {
        self.request = request
        self.storage = .init(request.application.sessionStorage.driver, sessionID: Self.sessionID)
    }

    /// save new or exising session
    ///
    /// Saving a new session will create a new session id and save that to the
    /// response. Thus a route that uses `save` needs to have the `.editResponse`
    /// option set. If you know the session already exists consider using
    /// `update` instead.
    public func save<Session: Codable>(session: Session, expiresIn: TimeAmount) -> EventLoopFuture<Void> {
        return self.storage.save(
            session: session,
            expiresIn: expiresIn,
            request: self.request
        )
    }

    /// update existing session
    ///
    /// If session does not exist then this function will do nothing
    public func update<Session: Codable>(session: Session, expiresIn: TimeAmount) -> EventLoopFuture<Void> {
        return self.storage.update(
            session: session,
            expiresIn: expiresIn,
            request: self.request
        )
    }

    /// load session
    public func load<Session: Codable>(as: Session.Type = Session.self) -> EventLoopFuture<Session?> {
        return self.storage.load(
            as: Session.self,
            request: self.request
        )
    }

    /// delete session
    public func delete() -> EventLoopFuture<Void> {
        return self.storage.delete(
            request: self.request
        )
    }

    /// Get session id gets id from request
    func getId() -> String? {
        switch Self.sessionID {
        case .cookie(let cookie):
            guard let sessionCookie = request.cookies[cookie]?.value else { return nil }
            return String(sessionCookie)
        case .header(let header):
            guard let sessionHeader = request.headers[header].first else { return nil }
            return sessionHeader
        }
    }

    /// set session id on response
    func setId(_ id: String) {
        precondition(
            self.request.extensions.get(\.response) != nil,
            "Saving a session involves editing the response via HBRequest.response which cannot be done outside of a route without the .editResponse option set"
        )
        switch Self.sessionID {
        case .cookie(let cookie):
            self.request.response.setCookie(.init(name: cookie, value: id))
        case .header(let header):
            self.request.response.headers.replaceOrAdd(name: header, value: id)
        }
    }

    /// create a session id
    static func createSessionId() -> String {
        let bytes: [UInt8] = (0..<32).map { _ in UInt8.random(in: 0...255) }
        return String(base64Encoding: bytes)
    }

    let request: HBRequest
    let storage: HBSessionStorage
}

extension SessionManager { /// save new or exising session
    /// save new or exising session
    ///
    /// Saving a new session will create a new session id and save that to the
    /// response. Thus a route that uses `save` needs to have the `.editResponse`
    /// option set. If you know the session already exists consider using
    /// `update` instead.
    public func save<Session: Codable>(session: Session, expiresIn: TimeAmount) async throws {
        return try await self.storage.save(
            session: session,
            expiresIn: expiresIn,
            request: self.request
        )
    }

    /// update existing session
    ///
    /// If session does not exist then a `sessionDoesNotExist` error will be thrown
    public func update<Session: Codable>(session: Session, expiresIn: TimeAmount) async throws {
        return try await self.storage.update(
            session: session,
            expiresIn: expiresIn,
            request: self.request
        )
    }

    /// load session
    public func load<Session: Codable>(as: Session.Type = Session.self) async throws -> Session? {
        return try await self.storage.load(
            as: Session.self,
            request: self.request
        )
    }

    /// delete session
    public func delete() async throws {
        return try await self.storage.delete(
            request: self.request
        )
    }
}

extension HBRequest {
    /// access session info
    public var session: SessionManager { return .init(request: self) }
}
