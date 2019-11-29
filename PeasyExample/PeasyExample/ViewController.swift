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
		server.start()
		let response = Response(status: .ok)
		let param = Request.QueryParameter(name: "test", value: "testvalue")
		server.respond(with: response, when: .path(matches: "/another-test"), .queryParameters(contain: param))
	}
	
	
}

