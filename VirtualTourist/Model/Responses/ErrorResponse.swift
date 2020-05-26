//
//  ErrorResponse.swift
//  VirtualTourist
//
//  Created by Vanessa on 5/25/20.
//  Copyright © 2020 Vanessa. All rights reserved.
//

import Foundation

struct ErrorResponse: Codable {
    let stat: String
    let code: Int
    let message: String
}
