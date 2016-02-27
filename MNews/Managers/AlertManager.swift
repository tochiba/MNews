//
//  AlertManager.swift
//  MNews
//
//  Created by 千葉 俊輝 on 2016/02/28.
//  Copyright © 2016年 Toshiki Chiba. All rights reserved.
//

import UIKit

class AlertManager: NSObject {
    static let sharedInstance = AlertManager()
    
    /*
    func showAppUpdateAlert(viewController: UIViewController?) {
        // UIAlertControllerを作成する.
        let myAlert: UIAlertController = UIAlertController(title: "お知らせ", message: "重要なアップデートがあります。App Storeで「みんなで作るニュース」のアップデートを行ってからご使用ください。", preferredStyle: .Alert)
        
        // OKのアクションを作成する.
        let myOkAction = UIAlertAction(title: "OK", style: .Default) { action in
            let str = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=753237901&mt=8"
            if let url = NSURL(string: str) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        
        // OKのActionを追加する.
        myAlert.addAction(myOkAction)
        
        // UIAlertを発動する.
        viewController?.presentViewController(myAlert, animated: true, completion: nil)
    }
    */
    
    func showBlackListAlert(viewController: UIViewController?) {
        // UIAlertControllerを作成する.
        let myAlert: UIAlertController = UIAlertController(title: "重要なお知らせ", message: "多数のユーザーから通報されたため、あなたのアカウントは凍結されました。" + "\n" + "解除したい場合は、メールで申請お願いします。", preferredStyle: .Alert)
        
        // OKのアクションを作成する.
        let myOkAction = UIAlertAction(title: "OK", style: .Default) { action in
            
            if let url = NSURL(string: "mailto:koganepj@gmail.com?subject=Unfreeze") {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        
        // OKのActionを追加する.
        myAlert.addAction(myOkAction)
        
        // UIAlertを発動する.
        viewController?.presentViewController(myAlert, animated: true, completion: nil)
    }
    
    func showIllegalUserAlert(viewController: UIViewController?, userID: String) {
        weak var vc = viewController
        
        let myAlert: UIAlertController = UIAlertController(title: "通報", message: "こちらのユーザーを通報しますか？", preferredStyle: .Alert)
        
        let myCancelAction = UIAlertAction(title: "やめとく", style: .Cancel) { action in
            
        }
        let myOkAction = UIAlertAction(title: "通報", style: .Destructive) { action in
            //RoomManager.sharedInstance.illegalUser(userID)
        }
        myAlert.addAction(myCancelAction)
        myAlert.addAction(myOkAction)
        
        vc?.presentViewController(myAlert, animated: true, completion: nil)
    }
    
    func showIllegalMessageAlert(viewController: UIViewController?, roomID: String, userID: String, text: String?) {
        weak var vc = viewController
        let myAlert: UIAlertController = UIAlertController(title: "通報", message: "こちらのメッセージを通報しますか？", preferredStyle: .Alert)
        
        let myCancelAction = UIAlertAction(title: "やめとく", style: .Cancel) { action in
            
        }
        let myOkAction = UIAlertAction(title: "通報", style: .Destructive) { action in
            //RoomManager.sharedInstance.illegalMessage(roomID, userID: userID, text: text)
        }
        myAlert.addAction(myCancelAction)
        myAlert.addAction(myOkAction)
        
        vc?.presentViewController(myAlert, animated: true, completion: nil)
    }
    
}
/*
class PushAlertManager {
    private class func ifNeedPushAlert() -> Bool {
        // Default is false
        return !NSUserDefaults.standardUserDefaults().boolForKey("SHOW_PUSH_ALERT")
    }
    
    class func setNeedPushAlert() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "SHOW_PUSH_ALERT")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func checkPushAlert(viewController: UIViewController?) {
        if ifNeedPushAlert() {
            weak var vc = viewController
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let nVC = storyboard.instantiateViewControllerWithIdentifier("PushViewController") as? PushViewController {
                vc?.presentViewController(nVC, animated: true, completion: nil)
            }
        }
    }
}
*/