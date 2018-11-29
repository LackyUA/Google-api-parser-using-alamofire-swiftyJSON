//
//  Router.swift
//  Gym login
//
//  Created by Dmytro Dobrovolskyy on 11/1/18.
//  Copyright © 2018 Dima Dobrovolskyy. All rights reserved.
//

import Alamofire

extension Request {
    public func debugLog() -> Self {
        #if DEBUG
        debugPrint(self)
        #endif
        return self
    }
}

enum Router: URLRequestConvertible {
    
    case getPlacesInRadius(location: String, radius: String, type: String, keyword: String, key: String)
    case getPlaceDetails(placeid: String, language: String, key: String)
    case getDistances(destinations: String, units: String, origins: String, key: String)
    case getDirection(original: String, destination: String, key: String)
    
    static let baseURLString = "https://maps.googleapis.com/maps/api"
    
    var method: HTTPMethod {
        switch self {
            
        case .getPlacesInRadius, .getPlaceDetails, .getDistances, .getDirection:
            return .get
        }
    }
    
    var path: String {
        switch self {
            
        case .getPlacesInRadius:
            return "/place/nearbysearch/json"
        case .getPlaceDetails:
            return "/place/details/json"
        case .getDistances:
            return "/distancematrix/json"
        case .getDirection:
            return "/directions/json"
            
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
            
        case .getPlacesInRadius(let location, let radius, let type, let keyword, let key):
            return [
                "location" : location,
                "radius" : radius,
                "type" : type,
                "keyword" : keyword,
                "key" : key
            ]
        case .getPlaceDetails(let placeid, let language, let key):
            return [
                "placeid" : placeid,
                "language" : language,
                "key" : key
            ]
        case .getDistances(let destinations, let units, let origins, let key):
            return [
                "destinations" : destinations,
                "units" : units,
                "origins" : origins,
                "key" : key
            ]
        case .getDirection(let original, let destination, let key):
            return [
                "origin" : original,
                "destination" : destination,
                "key" : key
            ]
            
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url: URL = try Router.baseURLString.asURL()
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        
        switch self {
            
        case .getPlacesInRadius, .getPlaceDetails, .getDistances, .getDirection:
            var params: [String : Any] = [:]
            parameters?.forEach { params[$0] = $1 }
            urlRequest = try URLEncoding.default.encode(urlRequest, with: params)
        }
        
        return urlRequest
    }
}
