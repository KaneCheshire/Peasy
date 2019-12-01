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
		
		let response: Response = .image
		server.respond(with: response, when: .path(matches: "/another-test"))
	}
	
}

extension Response {
	
	static let image: Response = {
		let image = UIImage(named: "sh")!.pngData()!
		let contentType = Response.Header(name: .contentType, value: "image/png")
		return Response(status: .ok, headers: [contentType], body: image)
	}()
	
}
