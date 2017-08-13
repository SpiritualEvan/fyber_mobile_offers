//
//  FOOffersTableViewCell.swift
//  FyberMobileOffers
//
//  Created by Won Cheul Seok on 2017. 8. 13..
//  Copyright © 2017년 Won Cheul Seok. All rights reserved.
//

import UIKit
import FLAnimatedImage
import RxSwift

final class FOOffersTableViewCell: UITableViewCell {

    static var reuseIdentifier: String { return "FOOffersTableViewCellIdentifier" }
    
    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var teaserLabel:UILabel!
    @IBOutlet private var thumbnailView:FLAnimatedImageView!
    @IBOutlet private var payoutLabel:UILabel!
    private var thumbnailSubscription:Disposable?
    
    public func displayModel(model:FOOfferModel?) {
        if nil == model {
            titleLabel.text = nil
            teaserLabel.text = nil
            payoutLabel.text = nil
            thumbnailView.image = nil
            thumbnailView.animatedImage = nil
            thumbnailSubscription?.dispose()
            thumbnailSubscription = nil
            return
        }
        titleLabel.text = model!.title
        teaserLabel.text = model!.teaser
        payoutLabel.text = String(model!.payout)
        
        thumbnailSubscription?.dispose()
        thumbnailView.image = nil
        thumbnailView.animatedImage = nil
        thumbnailSubscription = FOImageFetcher.shared.observableImageFetcher(imageURL: model!.thumbmailUrl)
            .subscribe(onNext: { [weak thumbnailView] (tuple: (image:UIImage?, gifImage:FLAnimatedImage?)) in
                guard let thumbnailView = thumbnailView else {
                    return
                }
                
                thumbnailView.image = tuple.image
                thumbnailView.animatedImage = tuple.gifImage
                
        }, onError: nil, onCompleted: nil, onDisposed: nil)
        
    }

}
