//
//  String.swift
//  BikeRouteFinder
//

import Foundation

extension Optional where Wrapped == String {

    var emptyIfNil: String {
        guard let self = self else { return "" }
        return self
    }
}

internal extension String {
    
    var whitespaceAppended: String {
        return self + " "
    }
}
