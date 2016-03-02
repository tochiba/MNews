//
//  ConfigViewController.swift
//  MNews
//
//  Created by 千葉 俊輝 on 2016/03/02.
//  Copyright © 2016年 Toshiki Chiba. All rights reserved.
//

import UIKit

class ConfigViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    enum SettingMenu : Int {
        case Help
        case Request
        case License
        case Review
        
        static let count = Review.rawValue + 1
    }
    struct SettingMenuString {
        static let help     = "ヘルプ"
        static let request  = "要望・不具合報告"
        static let license  = "ライセンス"
        static let review   = "⭐️をつける"
    }
    
    
    let cellName = "SettingCell"
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorInset = UIEdgeInsetsZero
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingMenu.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellName, forIndexPath: indexPath)
        
        if indexPath.row == 0 {
            cell.textLabel?.text = SettingMenuString.help
        }
        else if indexPath.row == 1 {
            cell.textLabel?.text = SettingMenuString.request
        }
        else if indexPath.row == 2 {
            cell.textLabel?.text = SettingMenuString.license
        }
        else if indexPath.row == 3 {
            cell.textLabel?.text = SettingMenuString.review
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            //Meyasubaco.showHelpListViewController(self)
        }
        else if indexPath.row == 1 {
            //Meyasubaco.showCommentViewController(self)
        }
        else if indexPath.row == 2 {
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        else if indexPath.row == 3 {
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            if let nVC = storyboard.instantiateViewControllerWithIdentifier("ReviewController") as? ReviewController {
//                nVC.delegate = self
//                self.presentViewController(nVC, animated: true, completion: nil)
//            }
        }
        self.tableView.reloadData()
    }

}