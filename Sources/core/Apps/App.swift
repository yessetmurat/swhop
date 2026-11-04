//
//  App.swift
//  SwhopCore
//
//  Created by Yesset Murat on 04.11.2026.
//

/// An app found by the scan of the app folders.
public struct App: Sendable {

    /// The bundle's file name without `.app`.
    public let name: String
    /// The bundle's full path.
    public let path: String
}
