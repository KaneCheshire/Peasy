# Peasy

A lightweight mock server written purely in Swift,
that you can run directly _in_ your UI tests, with no need for any external
process to be spun up as part of the tests. 🎉

## Quick start

Simply create and start a server in your tests, then tell it what to respond
with for requests:

```swift
import XCTest
import Peasy

class MyUITest: XCTestCase {

  let server = Server()

  override func setUp() {
    server.start() // Default port is 8880
    let ok = Response(status: .ok)
    server.respond(with: ok, when: .path(matches: "/"))
  }

  func test_someStuff() {
    // Run your tests that cause the app to call http://localhost:8880/
  }

}
```

## Starting and stopping the server

To start a Peasy server, just call `start`:

```swift
let server = Server()
server.start()
```

By default, Peasy starts the server on 8880, but you can override this and choose
any port you want:

```swift
server.start(port: 8080)
```

> NOTE: Starting two servers on the same port is not supported and will fail.

> NOTE: iOS simulators share the same network as your Mac, so you can communicate
directly with your Peasy server from Terminal, Safari or Postman on your Mac.

To stop a server (i.e. when tests finish), just call `stop`:

```swift
server.stop()
```

## Configuring responses

By default Peasy doesn't know how to respond to any requests made to it.

You'll need to tell Peasy what to respond with, which you do by building up a set
of rules that must be valid for an incoming request:

```swift
let response = Response(status: .ok)
server.respond(with: response, when: .path(matches: "/"))
```

You can provide multiple rules to filter responses further, for example, only matching
paths `"/"` for `GET` requests:

```swift
server.respond(with: response, when: .path(matches: "/"), .method(matches: .get))
```

Now, whenever Peasy receives a `GET` request matching the root path of `"/"`, it will respond
with an empty response of `200 OK`.

If none of Peasy's built in rules work for you, you can always provide a custom handler:

```swift
let customRule: Rule = .custom { request in
  return request.path.contains("/common/path")
}
server.respond(with: response, when: customRule)
```

## Intercepting requests

There might be times when you want to know when Peasy has received a request so you
you know how to respond or take some other action like track certain requests (i.e. analytics):

```swift
var analytics: [Request] = []
server.respond(with { request in
  analytics.append(request)
  return response
}, when: .path(matches: "/analytics-event"))
```

## Wildcards and variables in paths

It's common to use wildcards and variables in paths that may be dynamic. Peasy supports
this by allowing you to indicate which parts of the path can be dynamic with the `:variable`
syntax:

```swift
server.respond(with: response, when: .path(matches: "/constant/:variable"))
```

The name after `:` can be anything you like, but that path component must exist otherwise
the rule will fail to match (i.e. `"/constant/"` is not valid, but `"/constant/value"` is).

If you want to get the value of a variable you can do so using a key-value subscript on the
request:

```swift
server.respond(with { request in
  print("The value is", request["variable"])
  return response
}, when: .path(matches: "/constant/:variable"))
```

## FAQs

Q: Does Peasy run on a real device?

A: Yes! Peasy uses low level Darwin APIs built into the open-source bits of iOS and macOS.

---

Q: Can this ever break?

A: Technically yeah, but these APIs have been around forever and haven't been deprecated.

---

Q: Can I use this in my app for the App Store?

A: Peasy is designed for UI tests but also works in regular apps. Peasy doesn't use
any private APIs, so shouldn't be rejected, but it will also depend on what you're using Peasy for.

## Credits

Peasy was hugely inspired by Envoy's Embassy server, but it does too much and
is far too complicated for what I want to achieve. Peasy's interface is designed
to be the simplest and most accessible it can be.

Without Envoy's hard work, Peasy would not exist.
