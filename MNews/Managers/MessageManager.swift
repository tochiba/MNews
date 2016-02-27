//
//  MessageManager.swift
//  MNews
//
//  Created by 千葉 俊輝 on 2016/02/28.
//  Copyright © 2016年 Toshiki Chiba. All rights reserved.
//

import UIKit
import NCMB

class MessageManager: NSObject {
    static let sharedInstance = MessageManager()
    
    func uploadMessageImage(data: NSData) -> String {
        let fileName = NSUUID().UUIDString + ".jpg"
        var error: NSError?
        let file = NCMBFile.fileWithName(fileName, data: data)
        file.save(&error)
        return fileName
    }
    
    func getMessageImage(imageString: String) -> NSData {
        let fileName = imageString
        if let file = NCMBFile.fileWithName(fileName, data: nil) as? NCMBFile {
            return file.getFileData()
        }
        
        return NSData()
    }
}

class MessageCounter: NSObject {
    static let MESSAGE_COUNT_KEY = "MessageCountKey"
    static let MESSAGE_TOTAL_COUNT_KEY = "MessageTotalCountKey"
    
    class func add() {
        var i = getCount()
        i++
        NSUserDefaults.standardUserDefaults().setInteger(i, forKey: MESSAGE_COUNT_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        var t = getTotalCount()
        t++
        NSUserDefaults.standardUserDefaults().setInteger(t, forKey: MESSAGE_TOTAL_COUNT_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func reset() {
        NSUserDefaults.standardUserDefaults().setInteger(0, forKey: MESSAGE_COUNT_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func getCount() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey(MESSAGE_COUNT_KEY)
    }
    
    class func getTotalCount() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey(MESSAGE_TOTAL_COUNT_KEY)
    }
}
