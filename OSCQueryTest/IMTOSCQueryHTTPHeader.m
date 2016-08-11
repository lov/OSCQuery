//
//  IMTOSCQueryHTTPHeader.m
//  IMTOSCQueryTest
//
//  Created by Tamas Nagy on 11/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#import "IMTOSCQueryHTTPHeader.h"

@implementation IMTOSCQueryHTTPHeader

- (instancetype)init {
    
    if (self = [super init]) {
    
        [self setFields:[NSMutableDictionary new]];
        
        // initial values
        [self setType:HTTP_BODY];
        [self setRequestPath:@""];

    }
    
    return self;
}

+ (instancetype)parseHeader:(NSString *)header {
    
    IMTOSCQueryHTTPHeader *obj = [[IMTOSCQueryHTTPHeader alloc] init];
    
    NSMutableArray *lines = [[header componentsSeparatedByString:@"\r\n"] mutableCopy];
    
    
    // parse the first line,
    // which could a request or a status line (response)
    [obj parseFirstLine:[lines objectAtIndex:0]];
    
    // remove the first line
    [lines removeObjectAtIndex:0];
    
    // iterate thru the additional fields
    for (NSString *current in lines) {
    
        NSRange firstcolon = [current rangeOfString:@":"];
        
        if (firstcolon.location != NSNotFound) {
        
            NSString *key = [current substringToIndex:firstcolon.location];
            NSString *value = [[current substringFromIndex:firstcolon.location+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            [[obj fields] setObject:[value copy] forKey:key];
        }
        
    }
    
    return obj;
    
}

- (void)parseFirstLine:(NSString *)line {
    
    
    NSArray *parts = [line componentsSeparatedByString:@" "];
    
    // if the last element is the HTTP_SUPPORTED_VERSION string and the line contains 3 fields
    // then this is a request line
    if ([[parts lastObject] isEqualToString:HTTP_SUPPORTED_VERSION] && [parts count] == 3) {
    
        // if the first part is GET, this is a HTTP GET REQUEST
        if ([[parts firstObject] isEqualToString:@"GET"]) {
            
            [self setType:HTTP_REQUEST_GET];
        
        } else {
            
            // otherwise, this is something we don't handle yet
            [self setType:HTTP_REQUEST_UNKNOWN];
        }
        
        // set request path
        [self setRequestPath:[parts objectAtIndex:1]];
    
        // if the first part is HTTP/1.1 then this is a response
    } else if ([[parts firstObject] isEqualToString:HTTP_SUPPORTED_VERSION]) {
            
        // set the type
        [self setType:HTTP_RESPONSE];
        
        // the second part should be the status code
        [self setStatusCode:[[parts objectAtIndex:1] intValue]];
        
        // the other parts of the first line is not interesting here, since its just the textual representation of the status code
    }
}

- (BOOL)acceptsJSON {
    
    BOOL ret = NO;
    
    if ([self type] == HTTP_REQUEST_GET) {
    
        if ([[self fields] objectForKey:@"Accept"]) {
         
            NSString *val = [[self fields] objectForKey:@"Accept"];
            
            if ([val rangeOfString:HTTP_CONTENT_TYPE_JSON].location != NSNotFound) {
                
                ret = YES;
            }
        }

    }
    
    
    return ret;
}

- (BOOL)hasUserAgentField {

    BOOL ret = NO;
    
    if ([self type] == HTTP_REQUEST_GET) {
        
        if ([[self fields] objectForKey:@"User-Agent"]) {
            
            ret = YES;
        }
        
    }

    return ret;

}

- (NSInteger)contentLength {
    
    NSInteger ret = HTTP_NOLENGTH;
    
    if ([[self fields] objectForKey:@"Content-Length"]) {
        
        ret = [[[self fields] objectForKey:@"Content-Length"] integerValue];
    }
    
    return ret;
}

@end
