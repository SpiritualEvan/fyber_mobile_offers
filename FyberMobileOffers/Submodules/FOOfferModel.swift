//
//  FOOfferModel.swift
//  FyberMobileOffers
//
//  Created by Won Cheul Seok on 2017. 8. 13..
//  Copyright © 2017년 Won Cheul Seok. All rights reserved.
//

import UIKit

enum FOOfferModelError:Error, CustomNSError {
    
    case noTitleEntryInJson([String:Any])
    case noTeaserEntryInJson([String:Any])
    case noHiresThumbnailUrlInJson([String:Any])
    case noPayoutInJson([String:Any])
    case invaildThumbnailUrl(String)
    
    var errorCode: Int {
        switch self {
        case .noTitleEntryInJson(_): return 0
        case .noTeaserEntryInJson(_): return 1
        case .noHiresThumbnailUrlInJson(_): return 2
        case .noPayoutInJson(_): return 3
        case .invaildThumbnailUrl(_): return 4
        }
    }
    var errorUserInfo: [String : Any] {
        var message = ""
        switch self {
        case .noTitleEntryInJson(let json): message = "No title entry found in json json : \(json)"
        case .noTeaserEntryInJson(let json): message = "No title entry found in json json : \(json)"
        case .noHiresThumbnailUrlInJson(let json): message = "No title entry found in json json : \(json)"
        case .noPayoutInJson(let json): message = "No title entry found in json json : \(json)"
        case .invaildThumbnailUrl(let urlString): message = "Invaild thumbnail url : \(urlString)"
        }
        return [NSLocalizedDescriptionKey:message]
    }
}

struct FOOfferModel {
    var title:String!
    var teaser:String!
    var thumbmailUrl:URL!// hi resolution thumbnail
    var payout:String!
    
    init(json offerEntry:[String:Any]) throws {
        guard let title = offerEntry["title"] as? String,
            false == title.isEmpty else {
            throw FOOfferModelError.noTitleEntryInJson(offerEntry)
        }
        guard let teaser = offerEntry["teaser"] as? String,
            false == teaser.isEmpty else {
            throw FOOfferModelError.noTeaserEntryInJson(offerEntry)
        }
        guard let thumbnailUrlString = offerEntry["thumbnail"] as? String,
            false == thumbnailUrlString.isEmpty else {
            throw FOOfferModelError.noHiresThumbnailUrlInJson(offerEntry)
        }
        guard let payout = offerEntry["payout"] as? String,
            false == payout.isEmpty else {
            throw FOOfferModelError.noPayoutInJson(offerEntry)
        }
        
        self.title = title
        self.teaser = teaser
        
        if let thumbnailUrl = URL(string: thumbnailUrlString) {
            self.thumbmailUrl = thumbnailUrl
        }else {
            throw FOOfferModelError.invaildThumbnailUrl(thumbnailUrlString)
        }
        self.payout = payout
    }
}
