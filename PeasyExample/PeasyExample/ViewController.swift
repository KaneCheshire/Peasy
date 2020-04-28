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
    let session: URLSession = {
        let session = URLSession(configuration: .default)
        return session
    }()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		server.start()
        server.respond(with: .image, when: .path(matches: "/image"))
        server.respond(with: .json, when: .path(matches: "/json"))
        a(i: 0)
        b(i: 0)
	}
    
    private func a(i: Int) {
        let url = URL(string: "http://localhost:8880/image")!
        let startedA = Date()
        let task = session.dataTask(with: url, completionHandler: { data, _, error in
            print("A", i, Date().timeIntervalSince(startedA))
            assert(error == nil)
            self.b(i: i + 1)
        })
        task.resume()
    }
    
    private func b(i: Int) {
        let startedB = Date()
        let taskB = session.dataTask(with: URL(string: "http://localhost:8880/json")!, completionHandler: { data, _, error in
            print("B", i, Date().timeIntervalSince(startedB))
            assert(error == nil)
            self.a(i: i + 1)
        })
        taskB.resume()
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
