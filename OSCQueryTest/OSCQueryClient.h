//
//  OSCQueryClient.h
//  OSCQueryTest
//
//  Created by Tamas Nagy on 10/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "JSONKit.h"
#import "OSCQueryHTTPHeader.h"
#import "OSCQueryClientDelegate.h"

@interface OSCQueryClient : NSObject <GCDAsyncSocketDelegate> {

    GCDAsyncSocket *socket;
    
    NSString *host;
    int port;
    
    dispatch_queue_t queue;
    NSMutableArray *requests;
}

@property (weak) id<OSCQueryClientDelegate> delegate;

- (instancetype)initWithHost:(NSString *)host onPort:(int)port;

- (void)queryFullAddressSpace;
- (void)queryAddress:(NSString *)address;
- (void)disconnect;

@end
