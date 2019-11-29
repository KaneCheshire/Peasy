# Peasy

[WORK IN PROGRESS!]

Peasy is a lightweight mock server written purely in Swift,
that you can run directly in your UI tests, with no need for any external
process to be spun up as part of the tests.

Simply create and start a server in your tests, then tell it what to respond
with for requests:

```swift
import XCTest
import Peasy

class MyUITest: XCTestCase {

  let server = Server()

  override func setUp() {
    server.start()
    let ok = Response(status: .ok)
    server.respond(with: ok, when: .path(matches: "/"))
  }

  func test_someStuff() {
    // Run your tests that cause the app to call http://localhost:8881/
  }

}
```

>Peasy was hugely inspired by Envoy's Embassy server, but it does too much and
is far too complicated for what I want to achieve. Peasy's interface is designed
to be the simplest and most accessible it can be.
>Without Envoy's hard work, Peasy would not exist.
