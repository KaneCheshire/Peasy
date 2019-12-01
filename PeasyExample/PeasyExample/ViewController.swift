//
//  ViewController.swift
//  PeasyExample
//
//  Created by Kane Cheshire on 29/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import UIKit
import Peasy

final class ViewController: UIViewController {
	
	private let server = Server()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		server.start()
		server.respond(with: .image, when: .path(matches: "/image"))
		server.respond(with: .json, when: .path(matches: "/json")) { request in
			print("Request received", request)
		}
	}
	
}

extension Response {
	
	static let image: Response = {
		let image = UIImage(named: "sh")!.pngData()!
		let contentType = Response.Header(name: .contentType, value: "image/png")
		return Response(status: .ok, headers: [contentType], body: image)
	}()
	
	static let json: Response = {
		
		struct Object: Encodable {
			let title: String
			let value: Int
		}
		
		let contentType = Response.Header(name: .contentType, value: "application/json")
		let body = Object(title: "hello world", value: 1)
		return Response(status: .ok, headers: [contentType], body: body)
	}()
	
}
