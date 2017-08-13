//
//  FOOffersTableViewCell.swift
//  FyberMobileOffers
//
//  Created by Won Cheul Seok on 2017. 8. 13..
//  Copyright © 2017년 Won Cheul Seok. All rights reserved.
//

import UIKit

final class FOOffersTableViewCell: UITableViewCell {

    static var reuseIdentifier: String { return "FOOffersTableViewCellIdentifier" }
    
    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var teaserLabel:UILabel!
    @IBOutlet private var thumbnailView:UIImageView!
    @IBOutlet private var payoutLabel:UILabel!
    private var thumbnailDownloadTask:URLSessionDataTask?
    
    public func displayModel(model:FOOfferModel) {
        titleLabel.text = model.title
        teaserLabel.text = model.teaser
        payoutLabel.text = String(model.payout)
        
        thumbnailDownloadTask?.cancel()
        thumbnailDownloadTask = URLSession.shared.dataTask(with: model.thumbmailUrl) { [weak imageView] (data, response, error) in
            
            guard nil != imageView else {
                return
            }
            
            if let thumbnailData = data, let thumbnailImage = UIImage(data: thumbnailData) {
                imageView?.image = thumbnailImage
            }
        }
        thumbnailDownloadTask?.resume()
    }

}
