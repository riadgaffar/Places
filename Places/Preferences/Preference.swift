//
//  Preference.swift
//  Places
//
//  Created by Riad Gaffar on 11/29/19.
//  Copyright © 2019 rgi. All rights reserved.
//

import Foundation

struct Parameters: Codable {
    var intent:String
    var radius:String
    var query:String
    var ll:String
    var v:String
    var client_secret:String
    var client_id:String
}

private let _Preference_SharedInstance = Preference()

class Preference {    
    var pararms:Parameters?
    class var sharedInstance: Preference
    {
        return _Preference_SharedInstance
    }
    
    func parseConfigParams() -> Parameters {
        let path = Bundle.main.url(forResource: "Preference", withExtension: "plist")!
        let data = try! Data(contentsOf: path)
        return try! PropertyListDecoder().decode(Parameters.self, from: data)
    }
}



