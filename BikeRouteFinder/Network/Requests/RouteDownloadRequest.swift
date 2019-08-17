//
//  RouteDownloadRequest.swift
//  BikeRouteFinder
//

import Foundation

import Foundation

internal struct RouteDownloadRequest: APIRequest {

    typealias ResponseType = DetailedRoute

    var path: String {
        return "/api/routes/findOptimized"
    }

    var query: String? {
        return "startLocation=\(start)&endLocation=\(end)"
    }

    private let start: String

    private let end: String

    init(start: String, end: String) {
        self.start = start
        self.end = end
    }
}
