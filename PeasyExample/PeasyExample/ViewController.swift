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
		
		let image = UIImage(named: "sh")!
		let img = image.pngData()!
		let contentType = Response.Header(name: .contentType, value: "image/png")
		let response = Response(status: .ok, headers: [contentType], body: img)
		server.respond(with: response, when: .path(matches: "/another-test"))
		
		server.stop()
		server.start()
		server.respond(with: response, when: .path(matches: "/another-test"))
	}
	
}
