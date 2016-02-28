//
//  RoomManager.swift
//  MNews
//
//  Created by 千葉 俊輝 on 2016/02/28.
//  Copyright © 2016年 Toshiki Chiba. All rights reserved.
//

import UIKit
import Firebase
import NCMB

class Room: NSObject {
    var id: String = ""
    var title: String = ""
    var imageData = NSData()
    var joinUser: String = "0"
    var createUserID: String = ""
    var lastMessageDate: String = ""
}

struct RoomKey {
    static let idKey: String        = "id"
    static let titleKey: String     = "title"
    static let imageDataKey: String = "data"
    static let joinUserKey: String  = "joinUser"
    static let createUserIDKey: String = "createUserID"
    static let lastMessageDateKey: String = "lastMessageDate"
}

protocol RoomManagerDelegate: class {
    func refreshData(rooms: [Room])
}

class RoomManager: NSObject {
    static let sharedInstance = RoomManager()
    
    var ref: Firebase!
    var rooms = [Room]()
    var imageData = [String:NSData]()
    var delegate: RoomManagerDelegate?
    var dateFormatter: NSDateFormatter!
    
    var pushRoomUser = [String: [String]]()
    var pushUserDic = [String: NSDictionary]()
    var deviceID: String = ""
    
    override init() {
        super.init()
        let date_formatter: NSDateFormatter = NSDateFormatter()
        date_formatter.locale     = NSLocale(localeIdentifier: "ja")
        date_formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.dateFormatter = date_formatter
        
        setupFirebase()
        
//        OneSignal.defaultClient().IdsAvailable({ (deviceId, pushToken) in
//            self.deviceID = deviceId
//        })
    }
    
    func setupFirebase() {
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        // firebaseのセットアップ
        self.rooms = [Room]()
        self.ref = Firebase(url: FirebaseURL + "room/")
        
        // 最新25件のデータをデータベースから取得する
        // 最新のデータ追加されるたびに最新データを取得する
        self.ref.queryLimitedToLast(30).observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) in
            
            if  let id = snapshot.value[RoomKey.idKey] as? String,
                let title = snapshot.value[RoomKey.titleKey] as? String,
                let str = snapshot.value[RoomKey.imageDataKey] as? String,
                let cid = snapshot.value[RoomKey.createUserIDKey] as? String,
                let ld = snapshot.value[RoomKey.lastMessageDateKey] as? String {
                    let room = Room()
                    room.id = id
                    room.title = title
                    room.createUserID = cid
                    room.lastMessageDate = ld
                    
                    if let dic = snapshot.value[RoomKey.joinUserKey] as? NSDictionary {
                        if let keys = dic.allKeys as? [String] {
                            room.joinUser = String(keys.count)
                            self.pushRoomUser[room.id] = keys
                        }
                    }
                    
                    if let _data = self.imageData[id] {
                        room.imageData = _data
                    }
                    else {
                        let iData = self.getRoomImage(str)
                        room.imageData = iData
                        self.imageData[id] = iData
                    }
                    
                    self.rooms.append(room)
                    self.delegate?.refreshData(self.rooms)
            }
            // reload
            //dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.refreshData(self.rooms)
            //})
        })
        //})
        
        self.ref.queryLimitedToLast(25).observeEventType(FEventType.ChildChanged, withBlock: { (snapshot) in
            if let id = snapshot.value[RoomKey.idKey] as? String {
                if let dic = snapshot.value[RoomKey.joinUserKey] as? NSDictionary {
                    self.pushUserDic[id] = dic
                }
            }
        })
    }
    
    func getRooms() -> [Room] {
        return self.rooms
    }
    
    func getPushRoomUser(roomID: String) -> [String] {
        if let users = self.pushRoomUser[roomID] {
            
            var pusher = [String]()
            
            if let dic = self.pushUserDic[roomID] {
                for key in NSOrderedSet(array: users).array as! [String] {
                    if let value = dic[key] as? NSDictionary {
                        if let flag = value["isPush"] as? Bool {
                            if flag {
                                pusher.append(key)
                            }
                        }
                    }
                }
            }
            return pusher
            //return NSOrderedSet(array: users).array as! [String]
        }
        return []
    }
    
    private func getDeviceID() -> String {
        if self.deviceID == "" {
            return UserManager.sharedInstance.getUser().id
        }
        return self.deviceID
    }
    func isPushThisRoom(roomID: String) -> Bool {
        if let dic = self.pushUserDic[roomID] {
            if let value = dic[getDeviceID()] as? NSDictionary {
                if let flag = value["isPush"] as? Bool {
                    return flag
                }
            }
        }
        return true
    }
    
    func createRoom(roomID: String, data: NSData) {
        let ref = Firebase(url: FirebaseURL + "room/")
        
        let now = self.dateFormatter.stringFromDate(NSDate())
        let roomPath = roomID
        let roomImageID = uploadRoomImage(NSUUID().UUIDString, data: data)
        let userID = UserManager.sharedInstance.getUser().id
        let post = [
            RoomKey.idKey: roomPath,
            RoomKey.titleKey: roomID,
            RoomKey.imageDataKey: roomImageID,
            RoomKey.createUserIDKey: userID,
            RoomKey.lastMessageDateKey: now]
        
        ref.childByAppendingPath(roomPath).setValue(post)
        
//        let upost = [UserKey.idKey: userID]
//        ref.childByAppendingPath(roomPath + "/" + RoomKey.joinUserKey + "/" + userID).setValue(upost)
    }
    
    private func uploadRoomImage(roomID: String, data: NSData) -> String {
        let fileName = roomID + ".jpg"
        var error: NSError?
        let file = NCMBFile.fileWithName(fileName, data: data)
        file.save(&error)
        return fileName
    }
    
    private func getRoomImage(id: String) -> NSData {
        let fileName = id
        if let file = NCMBFile.fileWithName(fileName, data: nil) as? NCMBFile {
            return file.getFileData()
        }
        
        return NSData()
    }
    
    func refreshRoomLastMessageDate(roomID: String) {
        let now = self.dateFormatter.stringFromDate(NSDate())
        let ref = Firebase(url: FirebaseURL + "room/" + roomID)
        let post = [RoomKey.lastMessageDateKey: now]
        ref.updateChildValues(post)
    }
    
    func joinRoom(roomID: String) {
        let userID = UserManager.sharedInstance.getUser().id
        let isPush = self.isPushThisRoom(roomID)
        let upost = [UserKey.idKey: userID, "isPush": isPush]
        Firebase(url: FirebaseURL + RoomKey.joinUserKey + "/" + roomID + "/" + getDeviceID()).setValue(upost)
    }
    
    func removeRoom(roomID: String) {
        Firebase(url: FirebaseURL + "room/" + roomID).removeValue()
        setupFirebase()
    }
    
    func setRoomNotification(roomID: String, isPush: Bool) {
        let userID = UserManager.sharedInstance.getUser().id
        let upost = [UserKey.idKey: userID, "isPush": isPush]
        Firebase(url: FirebaseURL + RoomKey.joinUserKey + "/" + roomID + "/" + getDeviceID()).setValue(upost)
    }
    
    func illegalRoom(room: Room) {
        let ref = Firebase(url: FirebaseURL + "illegal/room/")
        let now = self.dateFormatter.stringFromDate(NSDate())
        let post = ["roomID": room.id, illegalKey.sendUserKey: UserManager.sharedInstance.getUser().id, "date": now]
        let postRef = ref.childByAppendingPath(now)
        postRef.setValue(post)
    }
    
    func illegalUser(userID: String) {
        let ref = Firebase(url: FirebaseURL + "illegal/user/")
        let now = self.dateFormatter.stringFromDate(NSDate())
        let post = ["userID": userID, illegalKey.sendUserKey: UserManager.sharedInstance.getUser().id, "date": now]
        let postRef = ref.childByAppendingPath(now)
        postRef.setValue(post)
    }
    
    func illegalMessage(roomID: String, userID: String, text: String?) {
        let ref = Firebase(url: FirebaseURL + "illegal/message/")
        let now = self.dateFormatter.stringFromDate(NSDate())
        var post = ["roomID": roomID, "userID": userID, "date": now, illegalKey.sendUserKey: UserManager.sharedInstance.getUser().id]
        if let text = text {
            post["message"] = text
        }
        let postRef = ref.childByAppendingPath(now)
        postRef.setValue(post)
    }
}

struct illegalKey {
    static let sendUserKey = "sendUserID"
}

