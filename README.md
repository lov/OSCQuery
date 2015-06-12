# OSCQuery
A basic (and experimental) implementation of the OSC Query Proposal at https://github.com/mrRay/OSCQueryProposal 

This repository implements an OSC Query Server and Client over TCP/HTTP 1.1, and a utility class for parsing HTTP headers.

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

* JSONKit: https://github.com/marcdown/JSONKit
* CocoaAsyncSocket: https://github.com/robbiehanson/CocoaAsyncSocket

