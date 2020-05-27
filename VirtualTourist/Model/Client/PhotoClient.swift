//
//  PhotoClient.swift
//  VirtualTourist
//
//  Created by Vanessa on 5/25/20.
//  Copyright © 2020 Vanessa. All rights reserved.
//

import Foundation

class PhotoClient {
    private static let apiKey = "ec69f7b541de933d8e3ca1e3174d73de"
    private static let format = "json"
    private static let searchRadius = 10
    private static let perpage = 20
    // we use this for random images
    private static var maxNumberOfPage = 1
    
    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest"
        static let searchMethod = "flickr.photos.search"
        
        case searchImages(lat: Double, lon: Double)
        
        var stringValue: String {
            switch self {
                case .searchImages(let lat, let lon):
                    // For demo purpose, we restrict the number of page between 1 to 10 
                    if maxNumberOfPage > 10 {
                        maxNumberOfPage = 10
                    }
                    let page = Int.random(in: 1...maxNumberOfPage)
                    return Endpoints.base + "?method=\(Endpoints.searchMethod)&api_key=\(apiKey)&lat=\(lat)&lon=\(lon)&radius=\(searchRadius)&page=\(page)&per_page=\(perpage)&format=\(format)&nojsoncallback=1&content_type=1&extras=url_s"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(ErrorResponse.self, from: data) as! Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        return task
    }
    
    class func getImagesForCoordinate(lat: Double, lon: Double, completion: @escaping ([String], Error?) -> Void) {
        print("URL: ", Endpoints.searchImages(lat: lat, lon: lon).url.absoluteString)
        taskForGETRequest(url: Endpoints.searchImages(lat: lat, lon: lon).url, responseType: ImageResponse.self) { response, error in
            if let response = response {
                let arr = response.photos.photo.map{ $0.url }
                maxNumberOfPage = response.photos.pages
                completion(arr, nil)
            } else {
                completion([], error)
            }
        }
    }
    
    class func downloadImage(url: String, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
}
