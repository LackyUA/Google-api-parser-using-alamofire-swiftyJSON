//
//  DataLoader.swift
//  Gym login
//
//  Created by Dmytro Dobrovolskyy on 11/1/18.
//  Copyright © 2018 Dima Dobrovolskyy. All rights reserved.
//

import Alamofire
import SwiftyJSON
import GooglePlaces
import GoogleMaps

class DataLoader {
    
    private static var manager = DataLoader().generateManager()
    
    private func generateManager() -> SessionManager {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Accept": "application/json",
                                               "Content-Type": "application/json"]
        let manager = Alamofire.SessionManager(configuration: configuration)
        
        return manager
    }
    
    func getPlacesInRadius(location: String, radius: String, type: String, keyword: String, key: String, completion: @escaping (_ result: [GymInfo]) -> Void) {
        var gyms = [GymInfo]()
        
        DataLoader.manager.request(Router.getPlacesInRadius(location: location, radius: radius, type: type, keyword: keyword, key: key)).debugLog().validate().responseJSON { response in
            let json = JSON(response.result.value as Any)
            
            for (_, gymJSON):(String, JSON) in json["results"] {
                
                let placeId = gymJSON["place_id"].stringValue
                let name = gymJSON["name"].stringValue

                gyms.append(GymInfo(name: name, location: "", phoneNumber: "", rating: 0.13, colorsForGradient: [.white, .black], distance: "", position: CLLocationCoordinate2D(latitude: 12.213, longitude: 0.12312), city: "", placeId: placeId))
            }
            
            completion(gyms)
        }
    }
    
    func getPlaceDetails(gym: GymInfo, key: String, completion: @escaping (_ result: GymInfo) -> Void) {
        DataLoader.manager.request(Router.getPlaceDetails(placeid: gym.placeId, language: Constants.language, key: key)).debugLog().validate().responseJSON { response in
            let json = JSON(response.result.value as Any)
            
            var gymJSON = json["result"]
            let phoneNumber = gymJSON["formatted_phone_number"].stringValue
            let rating = gymJSON["rating"].doubleValue
            let website = gymJSON["website"].stringValue
            let isOpen = gymJSON["opening_hours"]["open_now"].boolValue
            
            let currentDay = (Calendar.current.component(.weekday, from: Date()) - 1)
            var openingTime = String()
            for value in gymJSON["opening_hours"]["periods"].arrayValue {
                if currentDay == value["open"]["day"].intValue {
                    openingTime.append(value["open"]["time"].stringValue + " - ")
                    openingTime.append(value["close"]["time"].stringValue)
                    openingTime.insert(":", at: openingTime.index(openingTime.startIndex, offsetBy: 2))
                    openingTime.insert(":", at: openingTime.index(openingTime.startIndex, offsetBy: 10))
                }
            }
            let position = CLLocationCoordinate2D(
                latitude: gymJSON["geometry"]["location"]["lat"].doubleValue,
                longitude: gymJSON["geometry"]["location"]["lng"].doubleValue
            )
            var location = [String]()
            for (index, addressComponent) in gymJSON["address_components"].arrayValue.enumerated().reversed() where index < 2 {
                location.append(addressComponent["long_name"].stringValue)
            }
            var reviews = [GymInfo.Review]()
            for review in gymJSON["reviews"].arrayValue {
                reviews.append(GymInfo.Review(
                    authorName: review["author_name"].stringValue,
                    authorPhoto: review["profile_photo_url"].stringValue,
                    relativeTime: review["relative_time_description"].stringValue,
                    reviewText: review["text"].stringValue,
                    rating: review["rating"].doubleValue
                ))
            }
            
            gym.phoneNumber = phoneNumber
            gym.rating = rating
            gym.position = position
            gym.reviews = reviews
            gym.website = website
            gym.isOpen = isOpen
            gym.openingTime = openingTime
            if !location.isEmpty {
                gym.formatedAddress = "\(location[0]), \(location[1])"
            }
            
            completion(gym)
        }
    }
    
    func getDistances(destinations: String, units: String, origins: String, key: String, completion: @escaping (_ result: String) -> Void) {
        var result = [String]()
        
        DataLoader.manager.request(Router.getDistances(destinations: destinations, units: units, origins: origins, key: key)).debugLog().validate().responseJSON { response in
            let json = JSON(response.result.value as Any)
            
            for value in json["rows"].arrayValue {
                for distances in value["elements"].arrayValue {
                    result.append(distances["distance"]["text"].stringValue)
                }
            }
            
            completion(result.first ?? "")
        }
    }
    
    func getDirection(origin: String, destination: String, key: String, completion: @escaping (_ result: [GMSPolyline]) -> Void) {
        var polylines = [GMSPolyline]()
        
        DataLoader.manager.request(Router.getDirection(original: origin, destination: destination, key: key)).debugLog().validate().responseJSON { response in
            let json = JSON(response.result.value as Any)
            let routes = json["routes"].arrayValue
            
            for route in routes {
                let routeOverviewPolyline = route["overview_polyline"].dictionaryValue
                let routePoints = routeOverviewPolyline["points"]?.stringValue
                let path = GMSPath.init(fromEncodedPath: routePoints!)
                let polyline = GMSPolyline.init(path: path)
                
                polyline.strokeWidth = 4
                polyline.strokeColor = .red
                
                polylines.append(polyline)
            }
            
            completion(polylines)
        }
        
    }
    
}
