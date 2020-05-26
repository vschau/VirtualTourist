//
//  ImageResponse.swift
//  VirtualTourist
//
//  Created by Vanessa on 5/26/20.
//  Copyright © 2020 Vanessa. All rights reserved.
//

import Foundation

// MARK: - ImageResponse
struct ImageResponse: Codable {
    let photos: Images
    let stat: String
}

// MARK: - Photos
struct Images: Codable {
    let page, pages, perpage: Int
    let total: String
    let photo: [Image]
}

// MARK: - Image
struct Image: Codable {
    let id, owner, secret, server: String
    let farm: Int
    let title: String
    let ispublic, isfriend, isfamily: Int
    let url: String
    let height, width: Int

    enum CodingKeys: String, CodingKey {
        case id, owner, secret, server, farm, title, ispublic, isfriend, isfamily
        case url = "url_s"
        case height = "height_s"
        case width = "width_s"
    }
}
