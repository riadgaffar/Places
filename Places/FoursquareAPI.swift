//
//  FoursquareAPI.swift
//  Places
//
//  Created by Riad Gaffar on 11/21/19.
//  Copyright © 2019 rgi. All rights reserved.
//

import Foundation
import MapKit

class FoursquareAPI
{
    let FOURSQUARE_SEARCH_URL = "https://api.foursquare.com/v2/venues/search"
    
    static let shared = FoursquareAPI()

    var isQueryPending = false
    
    var params:Parameters?

    private init() {
        params = Preference.sharedInstance.parseConfigParams()
    }

    func query(location: CLLocation, searchText:String, completionHandler: @escaping ([[String: Any]]) -> Void)
    {
        if (isQueryPending == true || searchText.isEmpty)  {
            return
        }
        
        isQueryPending = true
                
        var places = [[String: Any]]()
        
        params?.query = searchText
        params?.ll = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        
        var urlComponents = URLComponents(string: FOURSQUARE_SEARCH_URL)!
        urlComponents.queryItems = []
        
        for (key, value) in Mirror(reflecting: params!).children {
            urlComponents.queryItems?.append(URLQueryItem(name: key!, value: value as? String))
        }
        
        let task = URLSession.shared.dataTask(with: urlComponents.url!, completionHandler: { data, response, error in
            
            if error != nil {
                print("*** ERROR *** \(error!.localizedDescription)")
                return
            }
            
            if data == nil || response == nil {
                print("*** SOMETHING WENT WRONG!!! ***")
                return
            }

            do {
                let jsonData = try JSONSerialization.jsonObject(with: data!, options: [])
                
                if  let jsonObject = jsonData as? [String: Any],
                    let response   = jsonObject["response"] as? [String: Any],
                    let venues     = response["venues"] as? [[String: Any]] {
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    numberFormatter.maximumFractionDigits = 2
                    for venue in venues
                    {
                        if  let name             = venue["name"] as? String,
                            let location         = venue["location"] as? [String: Any],
                            let latitude         = location["lat"] as? Double,
                            let longitude        = location["lng"] as? Double,
                            let formattedAddress = location["formattedAddress"] as? [String],
                            let distance         = location["distance"] as? Double
                            
                        {
                            places.append([
                                "name": name,
                                "address": formattedAddress.joined(separator: " "),
                                "latitude": latitude,
                                "longitude": longitude,
                                "distance": numberFormatter.string(from: NSNumber(value: distance * 0.000621371))!
                            ])
                        }
                    }
                }
                
                places.sort() { item1, item2 in
                    let distance1 = location.distance(from: CLLocation(latitude: item1["latitude"] as! CLLocationDegrees, longitude: item1["longitude"] as! CLLocationDegrees))
                    let distance2 = location.distance(from: CLLocation(latitude: item2["latitude"] as! CLLocationDegrees, longitude: item2["longitude"] as! CLLocationDegrees))
                    return distance1 < distance2
                }
            } catch {
                print("*** JSON ERROR *** \(error.localizedDescription)")
                return
            }
            
            self.isQueryPending = false
            
            DispatchQueue.main.async {
                completionHandler(places)
            }
        })

        task.resume()
    }
}
