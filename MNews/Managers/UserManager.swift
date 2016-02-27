//
//  UserManager.swift
//  MNews
//
//  Created by 千葉 俊輝 on 2016/02/28.
//  Copyright © 2016年 Toshiki Chiba. All rights reserved.
//

import UIKit
import Firebase
import NCMB
import KeychainAccess

class User: NSObject, NSCoding {
    var id:   String = ""
    var name: String = "匿名"
    var image: String = ""
    var limit: Bool = false
    
    override init() {
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        if let i = aDecoder.decodeObjectForKey(UserKey.idKey) as? String {
            self.id = i
        }
        if let n = aDecoder.decodeObjectForKey(UserKey.nameKey) as? String {
            self.name = n
        }
        if let im = aDecoder.decodeObjectForKey(UserKey.imageKey) as? String {
            self.image = im
        }
        
        self.limit = aDecoder.decodeBoolForKey(UserKey.limitKey)
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(id, forKey: UserKey.idKey)
        aCoder.encodeObject(name, forKey: UserKey.nameKey)
        aCoder.encodeObject(image, forKey: UserKey.imageKey)
        aCoder.encodeBool(limit, forKey: UserKey.limitKey)
    }
}

struct UserKey {
    static let idKey: String    = "id"
    static let nameKey: String  = "title"
    static let imageKey: String = "image"
    static let limitKey: String = "limit"
}

protocol UserManagerDelegate: class {
    func refreshUserInfo()
}

class UserManager: NSObject {
    static let sharedInstance = UserManager()
    let keychain = Keychain(service: "com.koganepj.minnews")
    var delegate: UserManagerDelegate?
    let USER_KEY = "UserKey"
    
    override init() {
        super.init()
        
        // niftyに移行用
        let user = getUser()
        if let data = NSData(base64EncodedString: user.image, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) {
            if let _ = UIImage(data: data) {
                let imageStr = uploadUserImage(user.id, data: data)
                user.image = imageStr
                setUser(user)
            }
        }
        
        // ブラックリスト用
        if let _ = keychain["USER_ID"], let _ = keychain["USER_NAME"] {
        }
        else {
            keychain["USER_ID"] = getUser().id
            keychain["USER_NAME"] = getUser().name
        }
        
    }
    
    func setUser(user: User) {
        let encodedData = NSKeyedArchiver.archivedDataWithRootObject(user)
        NSUserDefaults.standardUserDefaults().setObject(encodedData, forKey: USER_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        let ref = Firebase(url: FirebaseURL + "user/")
        let post = [UserKey.idKey: user.id, UserKey.nameKey: user.name, UserKey.imageKey: user.image]
        let postRef = ref.childByAppendingPath(user.id)
        postRef.setValue(post)
        self.delegate?.refreshUserInfo()
        
        keychain["USER_ID"] = user.id
        keychain["USER_NAME"] = user.name
    }
    
    func getUser() -> User {
        if let data = NSUserDefaults.standardUserDefaults().objectForKey(USER_KEY) as? NSData {
            if let user = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? User {
                return user
            }
        }
        
        let _user = User()
        
        if let userName = keychain["USER_NAME"] {
            _user.name = userName
        }
        if let userID = keychain["USER_ID"] {
            _user.id = userID
        }
        else {
            _user.id = NSUUID().UUIDString
        }
        
        setUser(_user)
        return _user
    }
    
    func uploadUserImage(userID: String, data: NSData) -> String {
        let fileName = userID + ".jpg"
        var error: NSError?
        let file = NCMBFile.fileWithName(fileName, data: data)
        file.save(&error)
        return fileName
    }
    
    func getUserImage(userID: String) -> NSData {
        let fileName = userID
        if let file = NCMBFile.fileWithName(fileName, data: nil) as? NCMBFile {
            return file.getFileData()
        }
        
        return NSData()
    }
    
}
