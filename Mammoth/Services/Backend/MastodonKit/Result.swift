//
//  Result.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 6/6/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public enum Result1<Model> {
    /// Success wraps a model and an optional pagination
    case success(Model, Pagination?)
    /// Failure wraps an ErrorType
    case failure(Error)
}

public extension Result1 {
    /// Convenience getter for the value.
    var value: Model? {
        switch self {
        case let .success(value, _): return value
        case .failure: return nil
        }
    }

    /// Convenience getter for the pagination.
    var pagination: Pagination? {
        switch self {
        case let .success(_, pagination): return pagination
        case .failure: return nil
        }
    }

    /// Convenience getter for the error.
    var error: Error? {
        switch self {
        case .success: return nil
        case let .failure(error): return error
        }
    }

    /// Convenience getter to test whether the result is an error or not.
    var isError: Bool {
        switch self {
        case .success: return false
        case .failure: return true
        }
    }
}
