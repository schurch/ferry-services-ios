//
//  VesselsAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 5/02/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Alamofire
import Interstellar

class VesselsAPIClient {
    #if DEBUG
    static let baseURL = NSURL(string: "http://stefanchurch.com:5678/")
    #else
    static let baseURL = NSURL(string: "http://stefanchurch.com:4567/")
    #endif
    
    static func fetchVessels() -> Signal<[Vessel]> {
        let url = NSURL(string: "vessels/", relativeToURL: VesselsAPIClient.baseURL)!
        
        let signal = Signal<[Vessel]>()
        
        Alamofire.request(.GET, url.absoluteString, parameters: nil).responseJSON { response in
            switch response.result {
            case .Success(let value):
                if let vesselsData = value as? [[String: AnyObject]] {
                    let vessels = vesselsData
                        .map( { Vessel(data: $0) } )
                        .flatMap( {$0} )
                    
                    signal.update(vessels)
                }
                else {
                    let error = NSError(domain: "com.stefanchurch.ferryservices.vesselsclient", code: 1, userInfo: nil)
                    signal.update(.Error(error))
                }
            case .Failure(let error):
                signal.update(error)
            }
        }
        
        return signal
    }
}
