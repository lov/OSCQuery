//
//  IMTOSCQueryServer.m
//  IMTOSCQueryTest
//
//  Created by Tamas Nagy on 10/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#import "IMTOSCQueryServer.h"


@implementation IMTOSCQueryServer

- (instancetype)initServerWithName:(NSString *)name onPort:(int)port withRootAddress:(NSString *)root {

    socket = nil;
    clients = nil;
    rootOSCAddress = nil;
    
    if (!name || !root || [name length] == 0 || [root length] == 0) return nil;
    
    if (self = [super init]) {
    
        socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        NSError *error = nil;
        if (![socket acceptOnPort:port error:&error])
        {
            NSLog(@"cannot start: %@", error);
            
            socket = nil;
            
            return nil;
        }
        
        clients = [NSMutableArray new];
        oscAddressSpace = [NSMutableDictionary new];
        queue =  dispatch_queue_create("com.imimot.IMTOSCQueryserverqueue", DISPATCH_QUEUE_SERIAL);

        [self setName:name];
        
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [dict setObject:[root copy] forKey:IMTOSCQuery_FULL_PATH];
        [dict setObject:[ROOT_NODE_DESCRIPTION copy] forKey:IMTOSCQuery_DESCRIPTION];
        [dict setObject:[NSMutableDictionary new] forKey:IMTOSCQuery_CONTENTS];
        
        [oscAddressSpace setObject:dict forKey:root];
        rootOSCAddress = [root copy];
        
        // support for ZeroConf
        netService = [[NSNetService alloc] initWithDomain:@"local."
                                                     type:@"_oscjson._tcp."
                                                     name:[NSString stringWithFormat:@"%@:%d", [self name], port]
                                                     port:port];
        
        if (netService) {
            [netService publish];
        }

    }
    
    return self;
}

- (void)dealloc {
    
    if (netService) {
        
        [netService stop];
        netService = nil;
    }
    
    if (socket) {
        
        [socket disconnect];
        socket = nil;
    }
    
    if (clients) {
        
        [clients removeAllObjects];
    }

}

#pragma mark Socket stuff


- (void)socket:(GCDAsyncSocket *)sender didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    //
    // new socket connected, store it as a reference
    //
    dispatch_sync(queue, ^{
        [clients addObject:newSocket];
    });
    
    NSLog(@"new client, yuppie!");
    
    
    // read the request from the client
    NSData *term = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    [newSocket readDataToData:term withTimeout:-1 tag:0];
    
    // once a client is connected, which means a http://host:port GET call, so we should send a reply
    // and provide our OSC address-space data in JSON format

}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    // read the content
    NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
 //   NSLog(@"content: %@", content);
    
    [self handleRequestOnSocket:sock withHeader:content];
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {

    //
    // socket disconnected, remove it from our references
    //
    dispatch_sync(queue, ^{
        [clients removeObject:sock];
    });

}

#pragma mark Handling requests

- (void)handleRequestOnSocket:(GCDAsyncSocket *)sock withHeader:(NSString *)srcheader {
    
    IMTOSCQueryHTTPHeader *source_header = [IMTOSCQueryHTTPHeader parseHeader:srcheader];
    
   // NSLog(@"request:%@ \n header fields: %@", [source_header requestPath], [source_header fields]);
    
    if ([source_header type] == HTTP_REQUEST_GET) {
    
        //
        // if the client has an User-Agent field then the client is probably a web browser
        // so we should close the socket after sending the info
        // supporting browser is
        // I.  useful for debugging
        // II. give users the possibility to discover the address space in a web browser
        //     which is cool especially if their OSC client does not support this OSC Query protocol
        //
        BOOL isBrowser = [source_header hasUserAgentField];
        
        NSString *dest_header = @"";
        
        __block NSData *body = nil;
        __block NSDictionary *dict = nil;
        
        // request full address space
        if ([[source_header requestPath] isEqualTo:@"/"]) {
            
            dispatch_sync(queue, ^{
                dict = [oscAddressSpace copy];
            });

        } else {
        
            
            dispatch_sync(queue, ^{
                dict = [self dictionaryForAddress:[source_header requestPath]];
            });

        
        }

        
        if (dict) {
        
            if (isBrowser) {
                
                dispatch_sync(queue, ^{
                    body = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
                });
                
                
            } else {
                
                dispatch_sync(queue, ^{
                    body = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
                });
                
            }

            // create header 200 OK header
            dest_header = HTTP_RESPONSE_HEADER_200_OK;
            
            // should post the length of the body here
            // since we don't support Chunked Transfer Encoding yet: http://en.wikipedia.org/wiki/Chunked_transfer_encoding
            // which is part of the HTTP/1.1 specification, so we should support that later
            dest_header = [dest_header stringByAppendingString:[NSString stringWithFormat:@"Content-Length: %ld\r\n", [body length]]];
            
            // must close the header here with an empty line
            dest_header = [dest_header stringByAppendingString:HTTP_RESPONSE_HEADER_CRLF];
            
            
            [sock writeData:[dest_header dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1.0 tag:0];

            // write the body part
            [sock writeData:body withTimeout:-1.0 tag:0];

        } else {
        
            // no data found, so send an error
            
            // create header 404 Not Found header
            dest_header = HTTP_RESPONSE_HEADER_404_ERROR;

            // must close the header here with an empty line
            dest_header = [dest_header stringByAppendingString:HTTP_RESPONSE_HEADER_CRLF];
            
            [sock writeData:[dest_header dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1.0 tag:0];

        }
        
        // if the client was a browser, we should close the socket here
        if (isBrowser) {
            
            [sock disconnectAfterWriting];
            
        } else {
        
            //
            // continue reading from the socket
            //
            NSData *term = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
            [sock readDataToData:term withTimeout:-1 tag:0];

        }

        
    }
    
}

#pragma mark Handling OSC addresses

- (void)addOSCAddress:(NSString *)address withDescription:(NSString *)description {
    
    //
    // An OSC address dictionary should at least have the following elements:
    //
    // FULL_PATH: The value stored with this string is the full OSC address path of the OSC node described by this object.
    // DESCRIPTION The value stored with this string is a string containing a human-readable description of this container/method. While not all OSC nodes are required to return a human-readable description, this attribute is listed as "required" because every implementation of this protocol should be able to recognize it.
    // CONTENTS The value stored with this string is a JSON object containing string:value pairs. the strings correspond to the names of sub-nodes, and the values stored with them are JSON objects that describe the sub-nodes. If the "CONTENTS" attribute is used, a single JSON object can be used to fully describe the attributes and hierarchy of every OSC method and container in an address space. This attribute will only be used within a JSON object that describes an OSC container. If this string:value pair is missing, the corresponding node should be assumed to be an OSC method (rather than a container).
    //
    //
    
    //  

    //
    // skip if the address is not a child of our rootOSCAddress
    //
    if (![[address substringToIndex:[rootOSCAddress length]] isEqualToString:rootOSCAddress]) {
    
        return;
    }
    
    NSArray *elements = [[address substringFromIndex:[rootOSCAddress length]] componentsSeparatedByString:@"/"];
    
//    NSLog(@"elements: %@", elements);
    
    dispatch_sync(queue, ^{

        NSMutableDictionary *lastContainer = [[oscAddressSpace objectForKey:rootOSCAddress] objectForKey:IMTOSCQuery_CONTENTS];
        NSString *addressCache = @"";
        if (![rootOSCAddress isEqualToString:@"/"]) {
            addressCache = [rootOSCAddress copy];
        }
        
        
        for (NSString *current in elements) {
            
            addressCache = [[addressCache stringByAppendingString:@"/"] stringByAppendingString:current];
            
            // if this is not the last element, which should not be an OSC container
            // we consider all other parts of this address space are containers
            // so create them if needed
            if (![current isEqualToString:[elements lastObject]]) {
                
                NSMutableDictionary *currentDict = [lastContainer objectForKey:current];
                
                // create the current element if does not exists
                if (!currentDict) {
                    
                    NSMutableDictionary *itemData = [NSMutableDictionary new];
                    [itemData setObject:@"container" forKey:IMTOSCQuery_DESCRIPTION];
                    [itemData setObject:[addressCache copy] forKey:IMTOSCQuery_FULL_PATH];
                    
                    [lastContainer setObject:itemData forKey:current];
                    currentDict = [lastContainer objectForKey:current];
                }
                
                NSMutableDictionary *currentContents = [currentDict objectForKey:IMTOSCQuery_CONTENTS];
                
                // create the current CONTENTS dictionary if does not exists
                if (!currentContents) {
                    
                    [currentDict setObject:[NSMutableDictionary new] forKey:IMTOSCQuery_CONTENTS];
                    currentContents = [currentDict objectForKey:IMTOSCQuery_CONTENTS];
                    
                }
                
                lastContainer = currentContents;
            }
            
        }
        
        // finally, construct and set the final address
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [dict setObject:[address copy] forKey:IMTOSCQuery_FULL_PATH];
        [dict setObject:[description copy] forKey:IMTOSCQuery_DESCRIPTION];
        [lastContainer setObject:dict forKey:[elements lastObject]];

    });

    
 //   NSLog(@"oscAddressSpace: %@", [oscAddressSpace JSONStringWithOptions:JKSerializeOptionPretty error:NULL]);
}

- (NSMutableDictionary *)dictionaryForAddress:(NSString *)address {

    NSMutableDictionary *ret = nil;
    
    NSMutableDictionary *currentDict = [[oscAddressSpace objectForKey:rootOSCAddress] objectForKey:IMTOSCQuery_CONTENTS];
    
    NSArray *elements = [[address substringFromIndex:[rootOSCAddress length]] componentsSeparatedByString:@"/"];

    for (NSString *current in elements) {
    
      //  NSLog(@"current: %@", current);

        ret = [currentDict objectForKey:current];
        
        if (!ret) {
            
            ret = [[currentDict objectForKey:IMTOSCQuery_CONTENTS] objectForKey:current];
        }
        
        currentDict = ret;
        
        if (!ret) {
            
            break;
        }
    }
    
    return ret;
    
}

- (void)setType:(NSString *)type forAddress:(NSString *)address {
    
    dispatch_sync(queue, ^{
        
        NSMutableDictionary *targetDict = [self dictionaryForAddress:address];
        
        if (targetDict) {
            
            // NSLog(@"targetDict: %@", targetDict);
            
            [targetDict setObject:[type copy] forKey:IMTOSCQuery_TYPE];
            
            //NSLog(@"oscAddressSpace: %@", [oscAddressSpace JSONStringWithOptions:JKSerializeOptionPretty error:NULL]);
            
        }
    });
    
    
}

- (void)setRangeWithMin:(NSNumber *)min max:(NSNumber *)max forAddress:(NSString *)address {

    dispatch_sync(queue, ^{
        
        NSMutableDictionary *targetDict = [self dictionaryForAddress:address];
        
        if (targetDict) {
            
            // NSLog(@"targetDict: %@", targetDict);
            
            NSMutableArray *range = [NSMutableArray new];
            
            if (min) {
                
                [range addObject:[min copy]];
                
            } else {
                
                [range addObject:[NSNull null]];
                
            }
            
            if (max) {
                
                [range addObject:[max copy]];
                
            } else {
                
                [range addObject:[NSNull null]];
                
            }
            
            // the third element should be null after min/max values here
            [range addObject:[NSNull null]];
            
            [targetDict setObject:[range copy] forKey:IMTOSCQuery_RANGE];
            
            //NSLog(@"oscAddressSpace: %@", [oscAddressSpace JSONStringWithOptions:JKSerializeOptionPretty error:NULL]);
            
        }
    });


}

@end