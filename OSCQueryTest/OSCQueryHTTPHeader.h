//
//  OSCQueryHTTPHeader.h
//  OSCQueryTest
//
//  Created by Tamas Nagy on 11/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCQueryDefinitions.h"

@interface OSCQueryHTTPHeader : NSObject {

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

- (NSInteger)contentLength;
@end
