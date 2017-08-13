//
//  FyberMobileOffersTests.swift
//  FyberMobileOffersTests
//
//  Created by Won Cheul Seok on 2017. 8. 12..
//  Copyright © 2017년 Won Cheul Seok. All rights reserved.
//

import XCTest
import RxSwift
@testable import FyberMobileOffers



class FyberMobileOffersTests: XCTestCase {

    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testHashGeneration() {
        
        // given example : HASHKEY CALCULATION section in https://ios.fyber.com/docs/rest-api-preparing-request
        let paramsDict = "appid=157&device_id=2b6f0cc904d137be2e1730235f5664094b831186&ip=212.45.111.17&locale=de&page=2&ps_time=1312211903&pub0=campaign2&timestamp=1312553361&uid=player1".components(separatedBy: "&")
            .map { (pairString) -> (String, String) in
                let pair = pairString.components(separatedBy: "=")
                return (pair[0], pair[1])
            }.reduce([String:String]()) { (dict, tuple) -> [String:String] in
                var joinedDict = dict
                joinedDict[tuple.0] = tuple.1
                return joinedDict
        }
        let resultHash = FOOffersFetcher.generateHash(params: paramsDict, apiKey: "e95a21621a1865bcbae3bee89c4d4f84")
        XCTAssertEqual(resultHash, "7a2b1604c03d46eec1ecd4a686787b75dd693c4d")
    }
    func testRx() {
        
        let onNextExpectation = expectation(description: "onNextExpectation")
        
        FOOffersFetcher.shared.observableFetcher()
        .subscribe(onNext: { (json) in
            print(json)
            onNextExpectation.fulfill()
        }, onError: { (error) in
            XCTFail(error.localizedDescription)
        }, onCompleted: nil, onDisposed: nil)
        self.waitForExpectations(timeout: 3) { (error) in
            XCTFail((error?.localizedDescription)!)
        }
        
        
        
        
        
    }
    
    
}
