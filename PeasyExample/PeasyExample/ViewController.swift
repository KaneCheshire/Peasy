//
//  ViewController.swift
//  PeasyExample
//
//  Created by Kane Cheshire on 29/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import UIKit
import Peasy

class ViewController: UIViewController {

    let server = Server()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        server.start()
    }


}

