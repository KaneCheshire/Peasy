# CHANGELOG

## Pending

- Added support for letting the system decide what available port to start on. (issue #27, #1) @ChaosCoder
- Peasy now chooses the available port by default, this may cause compatibility issues if you are expecting the default to be 8880.
- Added support for delaying responses, allowing you to simulate slow network conditions causing timeouts etc. (issue #15)

---

## 1.1.0

- Updated to find the _last_ matching config, not the first, allowing you to set default responses and then have overrides. (issue #23)
- Fixes API deprecation warnings.
- Added support for other platforms in Package.swift and Peasy.podspec. (issue #19)

---

## 1.0.1

- Added Carthage support.

---

## 1.0.0

- Initial release. 🎉
