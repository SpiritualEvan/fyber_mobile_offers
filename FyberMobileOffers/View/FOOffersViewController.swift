//
//  ViewController.swift
//  FyberMobileOffers
//
//  Created by Won Cheul Seok on 2017. 8. 12..
//  Copyright © 2017년 Won Cheul Seok. All rights reserved.
//

import UIKit
import RxSwift

final class FOOffersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet private var tableView:UITableView!
    var offers:[FOOfferModel] = []
    var disposeBag:DisposeBag!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disposeBag = DisposeBag()
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl!.addTarget(self, action: #selector(FOOffersViewController.refresh(_:)), for: .valueChanged)
        
        tableView.refreshControl!.beginRefreshing()
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - tableView.refreshControl!.frame.height), animated: true)
        refresh(nil)
        
    }
    @objc private func refresh(_ sender: Any?) {
        self.view.isUserInteractionEnabled = false
        FOOffersFetcher.shared.observableFetcher()
        .subscribe(onNext: { [weak self] (offers) in
            
            guard let strongSelf = self else {
                return
            }
            strongSelf.tableView.refreshControl!.endRefreshing()
            strongSelf.offers = offers
            strongSelf.tableView.reloadData()
            strongSelf.view.isUserInteractionEnabled = true
            
            
        }, onError: { [weak self] (error) in
            
            guard let strongSelf = self else {
                return
            }
            strongSelf.tableView.refreshControl!.endRefreshing()
            strongSelf.offers = []
            strongSelf.tableView.reloadData()
            
            let alertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
            strongSelf.present(alertController, animated: true, completion: nil)
            strongSelf.view.isUserInteractionEnabled = true
            
            
        }, onCompleted: nil, onDisposed:nil).addDisposableTo(disposeBag)
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0 == self.offers.count ? 1 : self.offers.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: FOOffersTableViewCell.reuseIdentifier, for: indexPath) as! FOOffersTableViewCell
        //shows no offer message
        if 0 == self.offers.count {
            cell.displayModel(model: nil)
            cell.textLabel?.text = true == (tableView.refreshControl?.isRefreshing) ? nil : "No offers. Pull down screen to refresh"
        }else {
            cell.displayModel(model: self.offers[indexPath.row])
            cell.textLabel?.text = nil
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
    }
}

