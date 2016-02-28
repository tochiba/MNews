//
//  CreateViewController.swift
//  MNews
//
//  Created by 千葉 俊輝 on 2016/02/28.
//  Copyright © 2016年 Toshiki Chiba. All rights reserved.
//

import UIKit
import Toast_Swift

class CreateUserViewController : CreateRoomViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let user = UserManager.sharedInstance.getUser()
        self.roomTitleLabel.text = user.name
        self.createButton.enabled = user.name.utf16.count > 0
        let data = UserManager.sharedInstance.getUserImage(user.image)
        if let image = UIImage(data: data) {
            self.imageView.image = image
            self.setImageButton.setTitle("", forState: .Normal)
        }
    }
    override func didPushCreateButton(sender: AnyObject) {
        guard let name = self.roomTitleLabel.text else {
            showToast("名前が設定されていません", title: "エラー")
            return
        }
        if name.utf16.count < 1 {
            showToast("名前が設定されていません", title: "エラー")
            return
        }
        
        let user = UserManager.sharedInstance.getUser()
        
        if let image = self.imageView.image {
            if let data = UIImageJPEGRepresentation(image, 0.5) {
                let imageStr = UserManager.sharedInstance.uploadUserImage(user.id, data: data)
                user.image = imageStr
            }
        }
        
        user.name = name
        UserManager.sharedInstance.setUser(user)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

protocol CreateRoomViewControllerDelegate: class {
    /**
     ルーム作成完了後に呼ばれる
     
     :param: vc   VRCreateRoomViewController
     :param: room 作成されたVRRoom
     */
    func createRoomController(vc: CreateRoomViewController, didCreateRoom room: Room)
}

class CreateRoomViewController: DialogViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    weak var delegate: CreateRoomViewControllerDelegate?
    
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var roomTitleLabel: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var setImageButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPushClose(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didPushCreateButton(sender: AnyObject) {
        guard let roomID = self.roomTitleLabel.text else {
            showToast("グループ名が設定されていません", title: "エラー")
            return
        }
        if roomID.utf16.count < 1 {
            showToast("グループ名が設定されていません", title: "エラー")
            return
        }
        
        guard let image = self.imageView.image else {
            showToast("グループの画像が設定されていません", title: "エラー")
            return
        }
        
        guard let data = UIImageJPEGRepresentation(image, 0.5) else {
            showToast("もう一度やり直してください", title: "エラー")
            return
        }
        
        RoomManager.sharedInstance.createRoom(roomID, data: data)
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didPushSetImageButton(sender: AnyObject) {
        let imagePicker           = UIImagePickerController()
        imagePicker.sourceType    = .PhotoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate      = self
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    private func showToast(message: String, title: String) {
        var style = ToastStyle()
        style.titleAlignment = NSTextAlignment.Right
        style.messageAlignment = NSTextAlignment.Right
        
        self.view.makeToast(message, duration: 2.0, position: self.view.center, title: title, image: UIImage(named: "iconColor1"), style: style) { (didTap: Bool) -> Void in
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            let newLength = text.utf16.count + string.utf16.count - range.length
            self.createButton.enabled = newLength > 0
        }
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        dismissViewControllerAnimated(true, completion: nil)
        
        self.setImageButton.setTitle("", forState: .Normal)
        self.imageView.image = image
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}

/**
 *  カスタムダイアログのベースクラス
 */
@IBDesignable class DialogViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    /**************************************************************************/
     // MARK: - Properties
     /**************************************************************************/
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            //popUpView?.layer.cornerRadius = cornerRadius
        }
    }
    
    /**************************************************************************/
     // MARK: - IBOutlet / UI
     /**************************************************************************/
    
    @IBOutlet weak var popUpView: UIView!
    
    
    
    /**************************************************************************/
     // MARK: - Initializer
     /**************************************************************************/
    
    required init(coder aDecoder: NSCoder) {
        //super.init(coder: aDecoder)
        super.init(coder: aDecoder)!
        self.modalPresentationStyle = .Custom
        self.transitioningDelegate = self
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .Custom
        self.transitioningDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        popUpView.layer.cornerRadius = cornerRadius
    }
    
    
    /**************************************************************************/
     // MARK: - UIViewControllerTransitioningDelegate
     /**************************************************************************/
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PopUpTransitionAnimater(presenting: true)
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PopUpTransitionAnimater(presenting: false)
    }
    
}


class PopUpTransitionAnimater : NSObject, UIViewControllerAnimatedTransitioning {
    var presenting: Bool
    
    init(presenting: Bool) {
        self.presenting = presenting
        super.init()
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.25
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toVC    = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let fromVC  = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toView  = transitionContext.viewForKey(UITransitionContextToViewKey)
        let fromView  =  transitionContext.viewForKey(UITransitionContextFromViewKey)
        
        let popUpView = presenting ? (toVC as! DialogViewController).popUpView : (fromVC as! DialogViewController).popUpView
        let containerView = transitionContext.containerView()
        
        toVC.view.frame     = containerView!.frame
        fromVC.view.frame   = containerView!.frame
        
        if let to = toView {
            containerView!.addSubview(to)
        } else if let from = fromView {
            containerView!.addSubview(from)
        }
        
        popUpView.transform = presenting ? CGAffineTransformMakeScale(0.05, 0.05) : CGAffineTransformMakeScale(1.0, 1.0)
        
        UIView.animateWithDuration(0.25,
            delay: 0.0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.6,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { () -> Void in
                popUpView.transform = self.presenting ?
                    CGAffineTransformMakeScale(1.0, 1.0) :
                    CGAffineTransformMakeScale(0.01, 0.01)
                if self.presenting {
                    toView?.alpha = 1.0
                } else {
                    fromView?.alpha = 0.0
                }
            }) { (finished: Bool) -> Void in
                transitionContext.completeTransition(finished)
        }
    }
    
}


