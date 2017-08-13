//
//  FMOOffersFetcher.swift
//  FyberMobileOffers
//
//  Created by Won Cheul Seok on 2017. 8. 13..
//  Copyright © 2017년 Won Cheul Seok. All rights reserved.
//

import UIKit
import RxSwift
import CryptoSwift

enum FMOOffersFetcherError :Error, CustomNSError   {

    
    case noJsonResponseFromServer
    case unableToParseJsonResponseIntoString(Data)
    case unableToParseJsonStringIntoDictionary(String)
    case noRootElementFound([String:Any])
    case noStatusCodeFound([String:Any])
    
    var errorCode: Int {
        switch self {
        case .noJsonResponseFromServer: return 0
        case .unableToParseJsonResponseIntoString(_): return 1
        case .unableToParseJsonStringIntoDictionary(_): return 2
        case .noRootElementFound(_): return 3
        case .noStatusCodeFound(_): return 4
        }
    }
    var errorUserInfo: [String : Any] {
        var message = ""
        switch self {
        case .noJsonResponseFromServer :
            message = "No json response returned from server"
        case .unableToParseJsonResponseIntoString(let data) :
            message = "Unable to parse response into string. response data :\(data)"
        case .unableToParseJsonStringIntoDictionary(let jsonString) :
            message = "Unable to parse json string into Dictionary. response string :\(jsonString)"
        case .noRootElementFound(let json) :
            message = "No root element found : \(json)"
        case .noStatusCodeFound(let json) :
            message = "No status code element found : \(json)"
        }
        return [NSLocalizedDescriptionKey : message]
    }
}
struct FMOOffer {
    
}
struct FMOOffersFetcher {
    
    static let shared = FMOOffersFetcher()
    
    public static func generateHash(params:[String:String]!, apiKey:String!) -> String {
        // reference : https://ios.fyber.com/docs/rest-api-preparing-request
        
        // 1. Get all request parameters and their values (except hashkey).
        // 2. Order theses pairs alphabetically by parameter name.
        let sortedPairs = params.sorted {$0.key < $1.key}
        
        // 3. Concatenate all pairs using = between key and value and & between the pairs.
        var concatenatedParamString = sortedPairs.reduce("") { "\($0)&\($1.key)=\($1.value)" }
        concatenatedParamString.remove(at: concatenatedParamString.startIndex) // remove first "&" character
        
        // 4. Concatenate the resulting string with & and the API Key given to you by Fyber.
        let hashTarget = "\(concatenatedParamString)&\(apiKey.lowercased())"
        
        // 5. Hash the whole resulting string, using SHA1. The resulting hashkey is then appended to the request as a separate parameter.
        return hashTarget.sha1().lowercased()
    }
    
    /*
     json
     appid: Application ID, provided as simple data
     uid: User ID, provided as simple data
     device_id: use Android advertising identifier
     locale: provided as simple data
     ip: provided as simple data
     offer_types: 112
     
     Sample app data
     appid: 2070
     uid: spiderman
     locale: ‘DE’
     ip: ‘109.235.143.113’
     API Key: 1c915e3b5d42d05136185030892fbb846c278927
     */
    public func observableFetcher() -> Observable<[String:Any]> {
        return Observable<[String:Any]>.create { observer in
            
            //
            // reference : https://ios.fyber.com/docs/rest-api-preparing-response
            //
            var params = ["appid":"2070",
                          "device_id": UIDevice.current.identifierForVendor!.uuidString,
                          "ip":"109.235.143.113",
                          "locale":"DE",
                          "page":"1",
                          "ps_time":"1312211903",
                          "pub0":"campaign2",
                          "timestamp":String(Date().timeIntervalSince1970),
                          "uid":"spiderman",
                          "offer_types":"112"]
            
            params["hashkey"] = FMOOffersFetcher.generateHash(params: params, apiKey: "1c915e3b5d42d05136185030892fbb846c278927")
            let paramsString = params.reduce(""){$0 + "&\($1.key)=\($1.value)"}
            let url = URL(string: "http://api.fyber.com/feed/v1/offers.json?\(paramsString)")!
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                guard nil == error else {
                    observer.onError(error!)
                    return
                }
                guard let data = data else {
                    observer.onError(FMOOffersFetcherError.noJsonResponseFromServer)
                    return
                }
                guard let jsonString = String(data: data, encoding: .utf8) else {
                    observer.onError(FMOOffersFetcherError.unableToParseJsonResponseIntoString(data))
                    return
                }
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String:Any] else {
                    observer.onError(FMOOffersFetcherError.unableToParseJsonStringIntoDictionary(jsonString))
                    return
                }
                guard let root = json["response"] as? [String:Any]  else {
                    observer.onError(FMOOffersFetcherError.noRootElementFound(json))
                    return
                }
                guard nil != root["code"] as? Int else {
                    observer.onError(FMOOffersFetcherError.noStatusCodeFound(json))
                    return
                }
                
                // can't check out status code whether it is ok or not.
                // no response code table exists
                // https://ios.fyber.com/docs/rest-api-preparing-response
                //                guard let statusCode = root["code"] as? Int else {
                //                    observer.onError(FMOOffersFetcherError.noStatusCodeFound(json:json))
                //                }
                
                
                observer.onNext(json)
            })
            task.resume()
            
            return Disposables.create() {
                task.cancel()
            }
            }
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
        
    }
}
