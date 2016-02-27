//
//  MessagesViewController.swift
//  MNews
//
//  Created by 千葉 俊輝 on 2016/02/28.
//  Copyright © 2016年 Toshiki Chiba. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase

class MessagesViewController: JSQMessagesViewController, UserManagerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var ref: Firebase!
    var room: Room = Room()
    var messages: [JSQMessage]?
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    var incomingAvatar: JSQMessagesAvatarImage!
    var outgoingAvatar: JSQMessagesAvatarImage!
    
    var dateFormatter: NSDateFormatter!
    var messageDateFormatter: NSDateFormatter!
    var icons = [String: UIImage]()
    var lastText: String = ""
    
    func setupFirebase() {
        
        // firebaseのセットアップ
        self.view.backgroundColor = UIColor.grayColor()
        RoomManager.sharedInstance.joinRoom(room.id)
        ref = Firebase(url: FirebaseURL + "room/" + room.id)
        
        // 最新25件のデータをデータベースから取得する
        // 最新のデータ追加されるたびに最新データを取得する
        ref.queryLimitedToLast(200).observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) in
            if  let sender = snapshot.value["from"] as? String,
                let name = snapshot.value["name"] as? String,
                let dateString = snapshot.value["date"] as? String,
                let date = self.dateFormatter.dateFromString(dateString) {
                    
                    if let text = snapshot.value["text"] as? String {
                        let message = JSQMessage(senderId: sender, senderDisplayName: name, date: date, text: text)
                        self.messages?.append(message)
                    }
                    
                    if let dataStr = snapshot.value["data"] as? String {                        
                        let data = MessageManager.sharedInstance.getMessageImage(dataStr)
                        if let image = UIImage(data: data) {
                            let media = JSQPhotoMediaItem(image: image)
                            media.appliesMediaViewMaskAsOutgoing = sender == self.senderId
                            let mediaMessage = JSQMessage(senderId: sender, senderDisplayName: name, date: date, media: media)
                            self.messages?.append(mediaMessage)
                        }
                    }
                    
            }
            self.finishReceivingMessage()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if room.id == "" {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        self.title = room.title
        setupDateFormatter()
        
        UserManager.sharedInstance.delegate = self
        //inputToolbar!.contentView!.leftBarButtonItem = nil
        automaticallyScrollsToMostRecentMessage = true
        
        
        //自分のsenderId, senderDisokayNameを設定
        let user = UserManager.sharedInstance.getUser()
        self.senderId = user.id
        self.senderDisplayName = user.name
        
        //吹き出しの設定
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        self.incomingBubble = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
        
        self.outgoingBubble = bubbleFactory.outgoingMessagesBubbleImageWithColor(BubbleColorAlpla)
        
        //アバターの設定
        let size = CGSize(width: 120, height: 120)
        self.incomingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage.colorImage(UIColor.lightGrayColor(), size: size), diameter: 120)
        
        self.outgoingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage.colorImage(UIColor.lightGrayColor(), size: size), diameter: 120)
        refreshUserInfo()
        
        //メッセージデータの配列を初期化
        self.messages = []
        setupFirebase()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.senderDisplayName == "匿名" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            if let nVC = storyboard.instantiateViewControllerWithIdentifier("CreateUserViewController") as? CreateUserViewController {
//                self.presentViewController(nVC, animated: true, completion: nil)
//            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupDateFormatter() {
        let date_formatter: NSDateFormatter = NSDateFormatter()
        date_formatter.locale     = NSLocale(localeIdentifier: "ja")
        date_formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.dateFormatter = date_formatter
        
        let mdate_formatter: NSDateFormatter = NSDateFormatter()
        mdate_formatter.locale     = NSLocale(localeIdentifier: "ja")
        mdate_formatter.dateFormat = " HH:mm "
        self.messageDateFormatter = mdate_formatter
    }
    
    private func showToast(message: String, title: String) {
//        var style = ToastStyle()
//        style.titleAlignment = NSTextAlignment.Left
//        style.messageAlignment = NSTextAlignment.Left
//        
//        self.view.makeToast(message, duration: 2.5, position: self.view.center, title: title, image: UIImage(named: "iconColor1"), style: style) { (didTap: Bool) -> Void in
//        }
    }
    
    func refreshUserInfo() {
        let user = UserManager.sharedInstance.getUser()
        self.senderDisplayName = user.name
        if let data = NSData(base64EncodedString: user.image, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) {
            if let image = UIImage(data: data) {
                self.outgoingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: 120)
                self.collectionView?.reloadData()
                return
            }
        }
        
        let data = UserManager.sharedInstance.getUserImage(user.image)
        if let image = UIImage(data: data) {
            self.outgoingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: 120)
        }
        
        self.collectionView?.reloadData()
    }
    private func getUserIcon(messageSenderId: String) -> JSQMessageAvatarImageDataSource {
        if messageSenderId == self.senderId {
            return self.outgoingAvatar
        }
        
        if let icon = icons[messageSenderId] {
            return JSQMessagesAvatarImageFactory.avatarImageWithImage(icon, diameter: 120)
        }
        else {
            Firebase(url: FirebaseURL + "user/" + messageSenderId + "/").queryLimitedToLast(25).observeEventType(FEventType.Value, withBlock: { (snapshot) in
                
                if let str = (snapshot.value as? NSDictionary)?.valueForKey(UserKey.imageKey) as? String {
                    
                    if let data = NSData(base64EncodedString: str, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) {
                        if let image = UIImage(data: data) {
                            self.icons[messageSenderId] = image
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                self.collectionView?.reloadData()
                            })
                        }
                    }
                    else {
                        let data = UserManager.sharedInstance.getUserImage(str)
                        if let image = UIImage(data: data) {
                            self.icons[messageSenderId] = image
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                self.collectionView?.reloadData()
                            })
                        }
                    }
                    
                }
            })
            
            return self.incomingAvatar
        }
    }
    
    private func pushNotification(text: String) {
        //dispatch_async(dispatch_get_main_queue(), {
        if self.lastText == text {
            return
        }
        
        let users = RoomManager.sharedInstance.getPushRoomUser(self.room.id)
//        OneSignal.defaultClient().postNotification(["contents": ["en": text], "include_player_ids": users, "ios_badgeCount": 1, "ios_badgeType": "Increase"], onSuccess: {(dic) in
//            
//            }, onFailure: {(error) in
//                
//        })
        //})
    }
    
    //Sendボタンが押された時に呼ばれる
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        //super.didPressSendButton(button, withMessageText: text, senderId: senderId, senderDisplayName: senderDisplayName, date: date)
        //メッセジの送信処理を完了する(画面上にメッセージが表示される)
        self.finishReceivingMessageAnimated(true)
        
        //firebaseにデータを送信、保存する
        let post1 = ["from": senderId, "name": senderDisplayName, "date": self.dateFormatter.stringFromDate(NSDate()), "text":text]
        let post1Ref = self.ref.childByAutoId()
        post1Ref.setValue(post1)
        
        RoomManager.sharedInstance.refreshRoomLastMessageDate(self.room.id)
        
        MessageCounter.add()
        
        pushNotification(senderDisplayName + "：" + text)
        self.finishSendingMessageAnimated(true)
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        if MessageCounter.getTotalCount() < 50 {
            let num = 50 - MessageCounter.getTotalCount()
            showToast("あと\(num)回コメントすると使えるようになります！\nお楽しみに！!", title: "画像送信機能")
        }
        else {
            let imagePicker           = UIImagePickerController()
            imagePicker.sourceType    = .PhotoLibrary
            imagePicker.allowsEditing = false
            imagePicker.delegate      = self
            presentViewController(imagePicker, animated: true, completion: nil)}
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        dismissViewControllerAnimated(true, completion: nil)
        
        guard let data = UIImageJPEGRepresentation(image, 0.3) else {
            return
        }
        //メッセジの送信処理を完了する(画面上にメッセージが表示される)
        self.finishReceivingMessageAnimated(true)
        
        //firebaseにデータを送信、保存する
        //let base64String = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        let imageString = MessageManager.sharedInstance.uploadMessageImage(data)
        let post1 = ["from": senderId, "name": senderDisplayName, "date": self.dateFormatter.stringFromDate(NSDate()), "data": imageString]
        let post1Ref = ref.childByAutoId()
        post1Ref.setValue(post1)
        
        self.finishSendingMessageAnimated(true)
    }
    
    
    //アイテムごとに参照するメッセージデータを返す
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return self.messages?[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        return attributeNameText(indexPath)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        return attributeText(indexPath)
    }
    
    private func attributeNameText(indexPath: NSIndexPath) -> NSAttributedString {
        var nameString = ""
        if let name = self.messages?[indexPath.item].senderDisplayName {
            nameString = " " + name + " "
        }
        return attribute(nameString)
    }
    
    private func attributeText(indexPath: NSIndexPath) -> NSAttributedString {
        var dateString = ""
        if let date = self.messages?[indexPath.item].date {
            dateString = self.messageDateFormatter.stringFromDate(date)
        }
        return attribute(dateString)
    }
    
    private func attribute(str: String) -> NSAttributedString {
        let font = UIFont(name: "HiraKakuProN-W3", size: 10) ?? UIFont.systemFontOfSize(10)
        
        let attr = [
            NSForegroundColorAttributeName: UIColor.darkGrayColor(),
            NSFontAttributeName: font]
        return NSAttributedString(string: str, attributes: attr)
    }
    
    //アイテムごとのMessageBubble(背景)を返す
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = self.messages?[indexPath.item]
        if message?.senderId == self.senderId {
            return self.outgoingBubble
        }
        return self.incomingBubble
    }
        
    //アイテムごとにアバター画像を返す
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = self.messages?[indexPath.item]
        if let id = message?.senderId {
            return getUserIcon(id)
        }
        
        return self.incomingAvatar
    }
    
    //アイテムの総数を返す
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.messages?.count)!
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
        
        let message = self.messages?[indexPath.item]
        if message?.senderId == self.senderId {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            if let nVC = storyboard.instantiateViewControllerWithIdentifier("CreateUserViewController") as? CreateUserViewController {
//                self.presentViewController(nVC, animated: true, completion: nil)
//            }
        }
        else {
            if let id = message?.senderId {
                AlertManager.sharedInstance.showIllegalUserAlert(self, userID: id)
            }
        }
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        let message = self.messages?[indexPath.item]
        
        if let media = message?.media as? JSQPhotoMediaItem {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            if let nVC = storyboard.instantiateViewControllerWithIdentifier("ImageViewerViewController") as? ImageViewerViewController {
//                nVC.image = media.image
//                self.presentViewController(nVC, animated: true, completion: nil)
//            }
        }
        else {
            if message?.senderId == self.senderId {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                if let nVC = storyboard.instantiateViewControllerWithIdentifier("CreateUserViewController") as? CreateUserViewController {
//                    self.presentViewController(nVC, animated: true, completion: nil)
//                }
            }
            else {
                if let id = message?.senderId {
                    AlertManager.sharedInstance.showIllegalMessageAlert(self, roomID: self.room.id, userID: id, text: message?.text)
                }
            }
        }
        
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapCellAtIndexPath indexPath: NSIndexPath!, touchLocation: CGPoint) {
        let message = self.messages?[indexPath.item]
        if message?.senderId == self.senderId {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            if let nVC = storyboard.instantiateViewControllerWithIdentifier("CreateUserViewController") as? CreateUserViewController {
//                self.presentViewController(nVC, animated: true, completion: nil)
//            }
        }
        else {
            if let id = message?.senderId {
                AlertManager.sharedInstance.showIllegalMessageAlert(self, roomID: self.room.id, userID: id, text: message?.text)
            }
        }
    }
}

public class JSQPhotoMediaItem: JSQMediaItem {
    
    private var _image: UIImage?
    public var image: UIImage? {
        
        get {
            
            return self._image
        }
        set {
            
            if self._image == newValue {
                
                return
            }
            
            self._image = newValue?.copy() as? UIImage
            self.cachedImageView = nil
        }
    }
    
    private var cachedImageView: UIImageView?
    
    // MARK: - Initialization
    
    public required override init() {
        
        super.init()
    }
    
    public required init(image: UIImage?) {
        
        super.init(maskAsOutgoing: true)
        
        self.image = image?.copy() as? UIImage
    }
    
    public required override init(maskAsOutgoing: Bool) {
        
        super.init(maskAsOutgoing: maskAsOutgoing)
    }
    
    public override var appliesMediaViewMaskAsOutgoing: Bool {
        
        didSet {
            
            self.cachedImageView = nil
        }
    }
    
    override public func clearCachedMediaViews() {
        
        super.clearCachedMediaViews()
        
        self.cachedImageView = nil
    }
    
    // MARK: - JSQMessageMediaData protocol
    public override func mediaView() -> UIView! {
        if let cachedImageView = self.cachedImageView {
            return cachedImageView
        }
        
        if let image = self.image {
            
            let size = self.mediaViewDisplaySize
            let imageView = UIImageView(image: image)
            imageView.frame = CGRectMake(0, 0, size().width, size().height)
            imageView.contentMode = .ScaleAspectFill
            imageView.clipsToBounds = true
            
            JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMaskToMediaView(imageView, isOutgoing: self.appliesMediaViewMaskAsOutgoing)
            self.cachedImageView = imageView
            
            return self.cachedImageView
        }
        
        return nil
    }
    
    // MARK: - NSObject
    
    public override var hash:Int {
        
        get {
            
            return super.hash^(self.image?.hash ?? 0)
        }
    }
    
    // MARK: - NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)!
        
        self.image = aDecoder.decodeObjectForKey("image") as? UIImage
    }
    
    public override func encodeWithCoder(aCoder: NSCoder) {
        
        super.encodeWithCoder(aCoder)
        
        aCoder.encodeObject(self.image, forKey: "image")
    }
    
    // MARK: - NSCopying
    
    public override func copyWithZone(zone: NSZone) -> AnyObject {
        
        let copy = self.dynamicType.init(image: UIImage(CGImage: (self.image?.CGImage)!))
        copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing
        return copy
    }
}

