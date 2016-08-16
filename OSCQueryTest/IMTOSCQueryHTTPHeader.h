//
//  IMTOSCQueryHTTPHeader.h
//  IMTOSCQueryTest
//
//  Created by Tamas Nagy on 11/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface IMTOSCQueryHTTPHeader : NSObject {

}

@property (strong) NSMutableDictionary *fields;
@property (assign) int type;
@property (copy) NSString *requestPath;
@property (assign) int statusCode;

+ (instancetype)parseHeader:(NSString *)header;

// indicates the request header can accept JSON
- (BOOL)acceptsJSON;

// indicates the request has a User-Agent field
- (BOOL)hasUserAgentField;

// length of the content
// return HTTP_NOLENGTH aka -1 if Content-Length: field cannot be found
- (NSInteger)contentLength;
@end
