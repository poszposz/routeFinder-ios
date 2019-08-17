//
//  GraphVisualiztionRequest.swift
//  BikeRouteFinder
//
//  Created by Jan Posz on 12.08.2018.
//  Copyright © 2018 agh. All rights reserved.
//

import Foundation

internal struct GraphVisualiztionRequest: APIRequest {
    
    typealias ResponseType = Graph

    var path: String {
        return "/api/routes/restrictedArea"
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
