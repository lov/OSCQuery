//
//  IMTOSCQueryClient.m
//  IMTOSCQueryTest
//
//  Created by Tamas Nagy on 10/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#import "IMTOSCQueryClient.h"
#import "IMTOSCQueryDefinitions.h"
#import "GCDAsyncSocket.h"

@interface IMTOSCQueryClient () <GCDAsyncSocketDelegate> {

}

@end

@implementation IMTOSCQueryClient

- (instancetype)initWithHost:(NSString *)_host onPort:(int)_port {
    
    socket = nil;
    host = _host;
    port = _port;
    
    if (self = [super init]) {
    
        socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [socket setDelegate:self];
        
       // [socket setIPv6Enabled:NO];
        
        NSError *error = nil;

        requests = [NSMutableArray new];
        queue =  dispatch_queue_create("com.imimot.IMTOSCQueryclientqueue", DISPATCH_QUEUE_SERIAL);

        if (![socket connectToHost:host onPort:port error:&error])
        {
            NSLog(@"error when connecting to the host: %@", [error localizedDescription]);
            
            [socket disconnect];
            
            socket = nil;
            
            return nil;
        }
        
        

    }
    
    return self;
}

- (void)dealloc {
    
    [self disconnect];
}

- (void)disconnect {
    
    [self setDelegate:nil];
    
    if (socket) {
        
        [socket setDelegate:nil];
        [socket disconnect];
        socket = nil;
    }
}

#pragma mark Socket stuff

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    
   // NSLog(@"cool, we just connected to the server!");
    
    //
    // once we connected to the socket, query the last cached request
    // which should be / on start
    //
    [self queryAddress:@"/"];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    IMTOSCQueryHTTPHeader *header = [IMTOSCQueryHTTPHeader parseHeader:dataString];
    
  //  NSLog(@"dataString: %@", dataString);
    
    if (header) {
    
        if ([header type] == HTTP_RESPONSE) {
            
            if ([header statusCode] == HTTP_STATUS_OK) {
            
                NSInteger content_length = [header contentLength];
                
                // NSLog(@"content_length: %ld", content_length);
                
                // we don't support Chunked Transfer Encoding (http://en.wikipedia.org/wiki/Chunked_transfer_encoding) yet
                // so only continue if we received a valid HTTP Content-Length field
                if (content_length != HTTP_NOLENGTH) {
                    
                    // so, just read the data
                    [sock readDataToLength:content_length withTimeout:-1 tag:0];
                    
                }

            } else if ([header statusCode] == HTTP_STATUS_NOT_FOUND) {
                
                // 404 error, notify our delegate
                
                __block NSString *request = @"";
                
                dispatch_sync(queue, ^{
                    request = [[requests firstObject] copy];
                    [requests removeObjectAtIndex:0];
                });

                if ([self delegate]) {
                    
                    [[self delegate] errorReceived:HTTP_STATUS_NOT_FOUND forRequest:request];
                }
            }
            
        } else if ([header type] == HTTP_BODY) {

            //
            // so, if the header is a HTTP_BODY, basically we could not perform
            // parsing of the header, which _probably_ means this is the body of a response
            //

           // NSLog(@"body: %@", requests);
            
            //
            // reply received, make an NSDictionary from it and post a notification with the data
            // but this is the behaviour of this client implementation
            // you can even post the JSON towards if needed
            //
            
            id dictFromJSON = [NSJSONSerialization JSONObjectWithData:[dataString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            
            if ([dictFromJSON isKindOfClass:[NSDictionary class]]) {
            
                if ([self delegate]) {
                    __block NSString *request = @"";
                    
                    dispatch_sync(queue, ^{
                        request = [[requests firstObject] copy];
                        [requests removeObjectAtIndex:0];
                    });

                    [[self delegate] replyReceived:dictFromJSON forRequest:request];
                }
            }
            
        }

    }
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
  //  NSLog(@"didWriteDataWithTag");
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    
    NSLog(@"socketDidDisconnect: %@", [err localizedDescription]);

}

#pragma mark Query method

- (void)queryFullAddressSpace {

    // create our header
    NSString *header = [[HTTP_GET_HEADER stringByReplacingOccurrencesOfString:@"_%GETURL%_" withString:@"/"] stringByReplacingOccurrencesOfString:@"_%HOST%_" withString:[NSString stringWithFormat:@"%@:%d", host, port]];
    
    dispatch_sync(queue, ^{
        [requests addObject:[@"/" copy]];
    });
    
    // post a GET / request to ask about the whole address space
    [socket writeData:[header dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    
    // Now we tell the socket to read the full header for the http response.
    // As per the http protocol, we know the header is terminated with two CRLF's (carriage return, line feed).
    NSData *responseTerminatorData = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    [socket readDataToData:responseTerminatorData withTimeout:-1.0 tag:0];

}

- (void)queryAddress:(NSString *)address {
    
    if (address) {
            
        // create our header
        NSString *header = [[HTTP_GET_HEADER stringByReplacingOccurrencesOfString:@"_%GETURL%_" withString:address] stringByReplacingOccurrencesOfString:@"_%HOST%_" withString:[NSString stringWithFormat:@"%@:%d", host, port]];
        

       // NSLog(@"header: %@", header);
        
        dispatch_sync(queue, ^{
            [requests addObject:[address copy]];
        });
        
        if ([socket isConnected]) {
            
            // post the request
            [socket writeData:[header dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
            
            // Now we tell the socket to read the full header for the http response.
            // As per the http protocol, we know the header is terminated with two CRLF's (carriage return, line feed).
            NSData *responseTerminatorData = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
            [socket readDataToData:responseTerminatorData withTimeout:-1.0 tag:0];
        
        } else {
        
            NSError *error = nil;
            
            if (![socket connectToHost:host onPort:port error:&error]) {
            
                //
                // OSCQuery servers should maintain persistent connections, but in case
                // we are disconnected at this time for whatever reason, its time to try to reconnect
                //
                
                [socket disconnect];
                
                NSLog(@"cannot reconnect to host: %@", [error localizedDescription]);
            }
            
        }


    }
    
}



@end
