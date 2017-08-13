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

enum FOOffersFetcherError :Error, CustomNSError   {

    
    case noJsonResponseFromServer
    case unableToParseJsonResponseIntoString(Data)
    case unableToParseJsonStringIntoDictionary(String)
    case noResponseSignatureFound
    case invalidResponseSignature(String, String)
    case noOffersEntryFound([String:Any])
    
    var errorCode: Int {
        switch self {
        case .noJsonResponseFromServer: return 0
        case .unableToParseJsonResponseIntoString(_): return 1
        case .unableToParseJsonStringIntoDictionary(_): return 2
        case .noResponseSignatureFound: return 5
        case .invalidResponseSignature(_, _): return 6
        case .noOffersEntryFound(_): return 7
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
        case .noResponseSignatureFound :
            message = "No response signature found in header."
        case .invalidResponseSignature(let expect, let actual) :
            message = "Invalid response signature in header. expected : \(expect), actual : \(actual)"
        case .noOffersEntryFound(let json) :
            message = "No offers entry found json : \(json)"
        }
        return [NSLocalizedDescriptionKey : message]
    }
}

struct FOOffersFetcher {
    
    private static let fyberApiKey = "1c915e3b5d42d05136185030892fbb846c278927"
    private static let fyberOffersApiUrl = "http://api.fyber.com/feed/v1/offers.json?"
    private static let signatureFieldKey = "X-Sponsorpay-Response-Signature"
    static let shared = FOOffersFetcher()
    
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
    public func observableFetcher() -> Observable<[FOOfferModel]> {
        return Observable<[String:Any]>.create { observer in
            
            //
            // reference : https://ios.fyber.com/docs/rest-api-preparing-response
            //
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
            
            // this hash value must match with signature of response header
            // see SIGNED RESPONSE section in https://ios.fyber.com/docs/rest-api-preparing-response
            let hashValue = FOOffersFetcher.generateHash(params: params, apiKey: FOOffersFetcher.fyberApiKey)
            params["hashkey"] = hashValue
            
            let paramsString = params.reduce(""){$0 + "&\($1.key)=\($1.value)"}
            let url = URL(string: "\(FOOffersFetcher.fyberOffersApiUrl)\(paramsString)")!
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                guard nil == error else {
                    observer.onError(error!)
                    return
                }
                
                guard let data = data else {
                    observer.onError(FOOffersFetcherError.noJsonResponseFromServer)
                    return
                }
                guard let jsonString = String(data: data, encoding: .utf8) else {
                    observer.onError(FOOffersFetcherError.unableToParseJsonResponseIntoString(data))
                    return
                }
                guard let signatureInResponse = (response as! HTTPURLResponse).allHeaderFields[FOOffersFetcher.signatureFieldKey] as? String else {
                    observer.onError(FOOffersFetcherError.noResponseSignatureFound)
                    return
                }
                guard signatureInResponse == (jsonString + FOOffersFetcher.fyberApiKey).sha1() else {
                    observer.onError(FOOffersFetcherError.invalidResponseSignature(hashValue, signatureInResponse))
                    return
                }
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String:Any] else {
                    observer.onError(FOOffersFetcherError.unableToParseJsonStringIntoDictionary(jsonString))
                    return
                }
                
                // can't check out status code in response now
//                guard nil != json["code"] as? Int else {
//                    observer.onError(FOOffersFetcherError.noStatusCodeFound(json))
//                    return
//                }
                
                // can't check out status code whether it is ok or not.
                // no response code table exists
                // https://ios.fyber.com/docs/rest-api-preparing-response
                //                guard let statusCode = root["code"] as? Int else {
                //                    observer.onError(FMOOffersFetcherError.noStatusCodeFound(json:json))
                //                }
                
                guard let offersDict = json["offers"] as? [[String:Any]] else {
                    observer.onError(FOOffersFetcherError.noOffersEntryFound(json))
                    return
                }
                let offers = offersDict.map { FOOfferModel(json: $0) }
                observer.onNext(json)
            })
            task.resume()
            
            return Disposables.create() {
                task.cancel()
            }
            }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
        
    }
}
