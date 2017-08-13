//
//  FOGifFetcher.swift
//  FyberMobileOffers
//
//  Created by Won Cheul Seok on 2017. 8. 13..
//  Copyright © 2017년 Won Cheul Seok. All rights reserved.
//

import UIKit
import RxSwift
import FLAnimatedImage
import ReachabilitySwift

enum FOImageFetcherError: CustomNSError {
    
    case noNetwork
    case noImageDataFromServer(URL)
    case curruptedImageData(URL)
    
    var errorCode: Int {
        switch self {
        case .noNetwork: return 0
        case .noImageDataFromServer(_): return 1
        case .curruptedImageData(_): return 2
        }
    }
    var errorUserInfo: [String : Any] {
        var message = ""
        switch self {
        case .noNetwork :
            message = "No network available. Please check device's internet connection."
        case .noImageDataFromServer(let url) :
            message = "No image data downloaded from server with url : \(url)"
        case .curruptedImageData(let url) :
            message = "Can't create image from data from url : \(url)"
        }
        return [NSLocalizedDescriptionKey : message]
    }
    
    
}

struct FOImageFetcher {
    
    static let shared = FOImageFetcher()
    
    public func observableImageFetcher(imageURL:URL!) -> Observable<(UIImage?, FLAnimatedImage?)> {
        return Observable<(UIImage?, FLAnimatedImage?)>.create { observer in
            
            guard true == Reachability()?.isReachable else {
                observer.onError(FOOffersFetcherError.noNetwork)
                return Disposables.create()
            }
            
            let task = URLSession.shared.dataTask(with: imageURL, completionHandler: { (data, response, error) in
                guard nil == error else {
                    observer.onError(error!)
                    return
                }
                
                guard let data = data else {
                    observer.onError(FOImageFetcherError.noImageDataFromServer(imageURL))
                    return
                }
                
                let isAnimatedImage = imageURL.pathExtension.lowercased() == "gif"
                if isAnimatedImage {
                    guard let thumbnailImage = FLAnimatedImage(gifData: data) else {
                        observer.onError(FOImageFetcherError.curruptedImageData(imageURL))
                        return
                    }
                    observer.onNext((nil, thumbnailImage))
                    observer.onCompleted()

                } else {
                    guard let thumbnailImage = UIImage(data: data) else {
                        observer.onError(FOImageFetcherError.curruptedImageData(imageURL))
                        return
                    }
                    observer.onNext((thumbnailImage, nil))
                    observer.onCompleted()
                }
                
            })
            task.resume()
            
            return Disposables.create() {
                task.cancel()
            }
            }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
    }

}
