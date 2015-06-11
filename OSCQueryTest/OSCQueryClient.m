//
//  OSCQueryClient.m
//  OSCQueryTest
//
//  Created by Tamas Nagy on 10/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#import "OSCQueryClient.h"
#import "OSCQueryDefinitions.h"

@implementation OSCQueryClient

- (instancetype)initWithHost:(NSString *)_host onPort:(int)_port {
    
    socket = nil;
    host = _host;
    port = _port;
    
    if (self = [super init]) {
    
        socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [socket setDelegate:self];
        
        NSError *error = nil;

        if (![socket connectToHost:host onPort:port error:&error])
        {
            NSLog(@"error when connecting to the host: %@", [error localizedDescription]);
            
            [socket disconnect];
            
            socket = nil;
            
            return nil;
        }
        
        [self setClientNotificationCenter:[NSNotificationCenter new]];
    }
    
    return self;
}

- (void)dealloc {
    
    [self disconnect];
}

- (void)disconnect {
    
    if (socket) {
        
        [socket setDelegate:nil];
        [socket disconnect];
        socket = nil;
    }
}

#pragma mark Socket stuff

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    
   // NSLog(@"cool, we just connected to the server!");
    
    [self queryFullAddressSpace];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    OSCQueryHTTPHeader *header = [OSCQueryHTTPHeader parseHeader:dataString];
    
    if (header) {
    
        if ([header type] == HTTP_RESPONSE && [header statusCode] == HTTP_STATUS_OK) {
            
            NSInteger content_length = [header contentLength];
            
           // NSLog(@"content_length: %ld", content_length);
            
            // we don't support Chunked Transfer Encoding (http://en.wikipedia.org/wiki/Chunked_transfer_encoding) yet
            // so only continue if we received a valid HTTP Content-Length field
            if (content_length != HTTP_NOLENGTH) {
                
                // so, just read the data
                [sock readDataToLength:content_length withTimeout:-1 tag:0];
                
            }
            
            //
            // so, if the header is a HTTP_BODY, basically we could not perform
            // parsing of the header, which _probably_ means this is the body of a response
            //
        } else if ([header type] == HTTP_BODY) {
            
           // NSLog(@"body: %@", dataString);
            
            //
            // reply received, make an NSDictionary from it and post a notification with the data
            // but this is the behaviour of this client implementation
            // you can even post the JSON towards if needed
            //
            
            id dictFromJSON = [dataString objectFromJSONString];
            
            if ([dictFromJSON isKindOfClass:[NSDictionary class]]) {
            
                [[self clientNotificationCenter] postNotificationName:OSC_QUERY_REPLY_RECEIVED object:self userInfo:dictFromJSON];
            }
            
        }

    }
    
}

#pragma mark Query method

- (void)queryFullAddressSpace {

    // create our header
    NSString *header = [[HTTP_GET_HEADER stringByReplacingOccurrencesOfString:@"_%GETURL%_" withString:@"/"] stringByReplacingOccurrencesOfString:@"_%HOST%_" withString:[NSString stringWithFormat:@"%@:%d", host, port]];
    
    // post a GET / request to ask about the whole address space
    [socket writeData:[header dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    
    // Now we tell the socket to read the full header for the http response.
    // As per the http protocol, we know the header is terminated with two CRLF's (carriage return, line feed).
    NSData *responseTerminatorData = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    [socket readDataToData:responseTerminatorData withTimeout:-1.0 tag:0];

}


@end
