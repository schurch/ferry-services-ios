//
//  APIError.swift
//  FerryServices_2
//
//  Created by Stefan Church on 29/08/20.
//  Copyright © 2020 Stefan Church. All rights reserved.
//

import Foundation

enum APIError: Error, LocalizedError {
    case missingResponseData
    case expectedHTTPResponse
    case badResponseCode
}
