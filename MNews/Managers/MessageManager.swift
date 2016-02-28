//
//  MessageManager.swift
//  MNews
//
//  Created by 千葉 俊輝 on 2016/02/28.
//  Copyright © 2016年 Toshiki Chiba. All rights reserved.
//

import UIKit
import Firebase
import NCMB
import JSQMessagesViewController

protocol MessageManagerDelegate: class {
    func refreshMessages(messages: [JSQMessage])
    func refreshIcons(icons: [String: UIImage])
}

class MessageManager: NSObject {
    static let sharedInstance = MessageManager()
    
    var ref: Firebase!
    var dateFormatter: NSDateFormatter!
    
    var messages = [JSQMessage]()
    var icons = [String: UIImage]()
    
    var delegate: MessageManagerDelegate?
    
    override init() {
        super.init()
        setupDateFormatter()
    }
    
    private func setupDateFormatter() {
        let date_formatter: NSDateFormatter = NSDateFormatter()
        date_formatter.locale     = NSLocale(localeIdentifier: "ja")
        date_formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.dateFormatter = date_formatter
    }
    
    func setupMessages(roomid: String) {
        RoomManager.sharedInstance.joinRoom(roomid)
        self.ref = Firebase(url: FirebaseURL + "message/" + roomid)
        self.messages = [JSQMessage]()
        let user = UserManager.sharedInstance.getUser()
        
        // 最新25件のデータをデータベースから取得する
        // 最新のデータ追加されるたびに最新データを取得する
        ref.queryLimitedToLast(200).observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) in
            if  let sender = snapshot.value[PostMessageKey.FromKey] as? String,
                let name = snapshot.value[PostMessageKey.SenderNameKey] as? String,
                let dateString = snapshot.value[PostMessageKey.DateKey] as? String,
                let date = self.dateFormatter.dateFromString(dateString) {
                    
                    if let text = snapshot.value[PostMessageKey.TextKey] as? String {
                        let message = JSQMessage(senderId: sender, senderDisplayName: name, date: date, text: text)
                        self.messages.append(message)
                    }
                    
                    if let dataStr = snapshot.value[PostMessageKey.ImageKey] as? String {
                        let data = MessageManager.getMessageImage(dataStr)
                        if let image = UIImage(data: data) {
                            let media = JSQPhotoMediaItem(image: image)
                            media.appliesMediaViewMaskAsOutgoing = sender == user.id
                            let mediaMessage = JSQMessage(senderId: sender, senderDisplayName: name, date: date, media: media)
                            self.messages.append(mediaMessage)
                        }
                    }
                    // 更新
                    self.delegate?.refreshMessages(self.messages)
            }
            // 更新
            self.delegate?.refreshMessages(self.messages)
        })
    }
    
    func getMessages() -> [JSQMessage] {
        return self.messages
    }
    
    func setupIcons(messageSenderId: String) {
        self.icons = [String: UIImage]()
        
        Firebase(url: FirebaseURL + "user/" + messageSenderId + "/").queryLimitedToLast(5).observeEventType(FEventType.Value, withBlock: { (snapshot) in
            if let str = (snapshot.value as? NSDictionary)?.valueForKey(UserKey.imageKey) as? String {
                let data = UserManager.sharedInstance.getUserImage(str)
                if let image = UIImage(data: data) {
                    self.icons[messageSenderId] = image
                    self.delegate?.refreshIcons(self.icons)
                }
            }
            self.delegate?.refreshIcons(self.icons)
        })
    }
    
    func getIcons() -> [String: UIImage] {
        return self.icons
    }

}

struct PostMessageKey {
    static let FromKey: String          = "from"
    static let SenderNameKey: String    = "name"
    static let DateKey: String          = "date"
    static let TextKey: String          = "text"
    static let ImageKey: String         = "data"
}

extension MessageManager {
    class func getFQuery(roomid: String) -> Firebase {
        return Firebase(url: FirebaseURL + "message/" + roomid)
    }
    
    class func getDateFormatter() -> NSDateFormatter {
        let date_formatter = NSDateFormatter()
        date_formatter.locale     = NSLocale(localeIdentifier: "ja")
        date_formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return date_formatter
    }
    
    class func sendMessage(senderId: String, text: String, senderDisplayName: String, roomid: String) {
        let query = getFQuery(roomid)
        
        let post = [
            PostMessageKey.FromKey: senderId,
            PostMessageKey.SenderNameKey: senderDisplayName,
            PostMessageKey.DateKey: getDateFormatter().stringFromDate(NSDate()),
            PostMessageKey.TextKey:text]
        
        let postRef = query.childByAutoId()
        postRef.setValue(post)
        
        RoomManager.sharedInstance.refreshRoomLastMessageDate(roomid)
        
        MessageCounter.add()
        
        pushNotification(senderDisplayName + "：" + text, roomid: roomid)
    }
    
    class func sendMessage(senderId: String, data: NSData, senderDisplayName: String, roomid: String) {
        let query = getFQuery(roomid)
        
        let imageString = self.uploadMessageImage(data)
        let post = [
            PostMessageKey.FromKey: senderId,
            PostMessageKey.SenderNameKey: senderDisplayName,
            PostMessageKey.DateKey: getDateFormatter().stringFromDate(NSDate()),
            PostMessageKey.ImageKey: imageString]
        
        let postRef = query.childByAutoId()
        postRef.setValue(post)
        
        RoomManager.sharedInstance.refreshRoomLastMessageDate(roomid)
        
        MessageCounter.add()
        
        pushNotification(senderDisplayName + "：" + "画像を送信しました", roomid: roomid)
    }

    class func uploadMessageImage(data: NSData) -> String {
        let fileName = NSUUID().UUIDString + ".jpg"
        var error: NSError?
        let file = NCMBFile.fileWithName(fileName, data: data)
        file.save(&error)
        return fileName
    }
    
    class func getMessageImage(imageString: String) -> NSData {
        let fileName = imageString
        if let file = NCMBFile.fileWithName(fileName, data: nil) as? NCMBFile {
            return file.getFileData()
        }
        
        return NSData()
    }
    class func pushNotification(text: String, roomid: String) {
//        let users = RoomManager.sharedInstance.getPushRoomUser(self.room.id)
//        OneSignal.defaultClient().postNotification(["contents": ["en": text], "include_player_ids": users, "ios_badgeCount": 1, "ios_badgeType": "Increase"], onSuccess: {(dic) in
//            
//            }, onFailure: {(error) in
//                
//        })
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
