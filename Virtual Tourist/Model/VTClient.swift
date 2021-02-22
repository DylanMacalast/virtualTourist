//
//  VTClient.swift
//  Virtual Tourist
//
//  Created by Dylan Macalast on 07/10/2020.
//  Copyright © 2020 DylanMacalast. All rights reserved.
//

import Foundation

class VTClient {
    static let apiKey = "12d8cd1f836d89152ceac895b7815659"
    
    struct Auth {
        static var longitude: Double = 0
        static var latitude: Double = 0
    }
    
    
    enum Endpoints {
        
//    example    "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=12d8cd1f836d89152ceac895b7815659&lat=42.444&lon=-1.343&extras=url_n&per_page=30&format=json&nojsoncallback=1"
        
        
        static let base = "https://api.flickr.com/services/rest/?method="
        
        static let apiParam = "api_key=12d8cd1f836d89152ceac895b7815659"
        static let formatParam = "&format=json"
        static let jsonFormatParam = "&nojsoncallback=1"
        
        case searchForPhotos(page: Int, lat: Double, long: Double)
        
        var stringValue: String {
            switch self {
            case .searchForPhotos(let page, let lat, let lon): return  "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(VTClient.apiKey)&lat=\(lat)&lon=\(lon)&extras=url_n&per_page=30&page=\(page)&format=json&nojsoncallback=1"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    
    // function to search for photos
    class func searchForPhotos(lat: Double, lon: Double, completionHandler: @escaping(Photos?, Error?) -> Void) {
        
        let randPage = Int.random(in: 1...5)
        
        var request = URLRequest(url: Endpoints.searchForPhotos(page: randPage,lat: lat, long: lon).url)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error)
            in
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            
            // if there is data, code will carry on running
            let decoder = JSONDecoder()
            do {
                let responseObj = try decoder.decode(SearchPhoto.self, from: data)
                completionHandler(responseObj.photos, nil)
            } catch {
                completionHandler(nil, error)
                print(error)
            }
        }
        task.resume()
    }
    
    
    
    // function to get data from image url
    class func fetchImage(from urlString: String, completionHandler: @escaping (_ data: Data?) -> ()) {
       // init URLSession
       let session = URLSession.shared
       // the image url
       let url = URL(string: urlString)
       // init and start data task
       let dataTask = session.dataTask(with: url!) {
           (data, response, error)
           in
           if error != nil {
               print("error fetching image!")
               completionHandler(nil)
           } else {
               completionHandler(data)
           }
           
       }
       dataTask.resume()
    }
    
    
    
}
