//
//  ViewController.swift
//  MNews
//
//  Created by 千葉 俊輝 on 2016/02/23.
//  Copyright © 2016年 Toshiki Chiba. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.performSegueWithIdentifier(MainStoryboard.ViewControllers.showMessageViewControllerFromHome, sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

