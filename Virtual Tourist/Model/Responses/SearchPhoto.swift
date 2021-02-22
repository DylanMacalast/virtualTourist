//
//  SearchPhotoResponses.swift
//  Virtual Tourist
//
//  Created by Dylan Macalast on 07/10/2020.
//  Copyright © 2020 DylanMacalast. All rights reserved.
//

import Foundation


struct SearchPhoto: Codable {
    
    let photos: Photos
    let stat: String?
    
    enum CodingKeys: String, CodingKey {
        case photos
        case stat
    }
}


struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let images: [Image]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perpage
        case total
        case images = "photo"
        
    }
}

struct Image: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int?
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isFamily: Int?
    let url_n: String?
}
