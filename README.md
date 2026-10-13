# OSCQuery
A basic (and experimental) implementation of the OSC Query Proposal at https://github.com/mrRay/OSCQueryProposal 

This repository implements an OSC Query Server and Client over TCP/HTTP 1.1, and a utility class for parsing HTTP headers.

## Building

Open `OSCQueryTest.xcodeproj` in Xcode and build the `OSCQuery` scheme to build the framework. The repository also includes the `OSCQueryTest` scheme, which builds the sample app against `OSCQuery.framework`.

Command line builds:

```bash
xcodebuild build -project OSCQueryTest.xcodeproj -scheme OSCQuery -destination 'platform=macOS'
xcodebuild build -project OSCQueryTest.xcodeproj -scheme OSCQueryTest -destination 'platform=macOS'
```

## Usage

Apps can import the framework umbrella header:

```objc
#import <OSCQuery/OSCQuery.h>
```

The sample app links and embeds `OSCQuery.framework`. CocoaAsyncSocket's TCP `GCDAsyncSocket` source is vendored under `OSCQueryTest/Vendor/CocoaAsyncSocket/` and built by the framework target.

## OSCQueryServer

* ZeroConf/Bonjour support
* Adding OSC addresses with the minium info (FULL_PATH, DESCRIPTION, CONTENTS)
* Set TYPE and RANGE for OSC addresses
* GET the full- or partial OSC address space
* Basic error reporting (only 404 yet)
* Basic persistent connection management
* Browser "support"

The repository contains a simple sample app, although it may change very often, it could be considered as buggy, but somehow working.

## OSCQueryClient

* Query full- or partial address space 
* Basic error handling (only 404 yet)
* Delegate methods for forwarding reply and error data

## OSCQueryHTTPHeader

This class is used to parse a raw HTTP header and get the HTTP fields as well as some additional info

## System requirements

* Tested on OSX 10.10.3, should work on >=10.8
* 64bit, ARC

## 3rd party code

* CocoaAsyncSocket: https://github.com/robbiehanson/CocoaAsyncSocket

## Discovery naming

Use the extended server initializer when the name returned by `HOST_INFO` should differ from the Bonjour advertisement. For example, the display name can remain a complete multilingual name while the advertisement uses a shorter label.

`serviceNameProvider` returns the entire Bonjour label, including any port and collision suffix. The first attempt uses collision index 1; later collisions ask the provider for the next label. Budget the complete label within Bonjour's 63-byte UTF-8 limit. A nil provider keeps the original `name:port` label and automatic Bonjour renaming.

`publicationErrorHandler` receives listener startup failures synchronously and Bonjour publication failures later on the publishing thread's run loop. Both blocks are copied. Use each server from one thread with a running run loop; use nil for the handler when no reporting is needed. Existing callers can continue using the original initializer.

`renameWithName:serviceNameProvider:publicationErrorHandler:` updates `HOST_INFO` and republishes only Bonjour. The listener, existing connections and registered addresses remain in place. Calling it with the same name still republishes, allowing a failed advertisement to be retried. Renaming a stopped server prepares the next advertisement without restarting it; renaming after `removeResources` does nothing. A publication failure is reported without rolling back the new display name.

The sample app's **Server 1 name** field and **Rename** button exercise this API on the first local test server. Connect to that server first, enter a new name, and click Rename or press Return. Request `/?HOST_INFO` and `/ping` afterward without reconnecting to check the updated name and retained address space. The second test server keeps its original initializer and name.

The sample keeps the full entered name in `HOST_INFO`. Its Bonjour formatter reserves the port and collision suffix, then shortens long names at composed-character boundaries to fit the complete label within 63 UTF-8 bytes. Empty names are rejected, and publication failures appear in the sample log.
