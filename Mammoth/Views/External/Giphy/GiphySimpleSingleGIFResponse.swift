//
//  GiphySimpleSingleGIFResponse.swift
//  Pods
//
//  Created by Brendan Lee on 3/15/17.
//
//

import Foundation

public struct GiphySimpleSingleGIFResponse: Mappable {
    public fileprivate(set) var gif: GiphySimpleItem?

    public fileprivate(set) var meta: GiphyMeta?

    public init?(map _: Map) {}

    public mutating func mapping(map: Map) {
        gif <- map["data"]
        meta <- map["meta"]
    }
}
