//
//  VesselsAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/09/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation
//import RxSwift

struct VesselsAPIClient {
    #if DEBUG
    static let baseURL = URL(string: "http://test.scottishferryapp.com")
    #else
    static let baseURL = URL(string: "http://www.scottishferryapp.com")
    #endif
    
//    static func fetchVessels() -> Observable<[Vessel]> {
//        let url = URL(string: "/vessels/", relativeTo: VesselsAPIClient.baseURL)!
//
//        return Observable.create { observer in
//            let request = Alamofire.request(url.absoluteString).responseJSON { response in
//                switch response.result {
//                case .success(let value):
//                    if let vesselsData = value as? [[String: AnyObject]] {
//                        let vessels = vesselsData
//                            .map( { Vessel(data: $0) } )
//                            .flatMap( {$0} )
//
//                        observer.onNext(vessels)
//                        observer.onCompleted()
//                    }
//                    else {
//                        let error = NSError(domain: "com.stefanchurch.ferryservices.vesselsclient", code: 1, userInfo: nil)
//                        observer.onError(error)
//                    }
//                case .failure(let error):
//                    observer.onError(error)
//                }
//
//            }
//
//            return Disposables.create {
//                request.cancel()
//            }
//        }
//    }
}
