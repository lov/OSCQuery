//
//  IMTOSCQueryClient.h
//  IMTOSCQueryTest
//
//  Created by Tamas Nagy on 10/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "IMTOSCQueryHTTPHeader.h"
#import "IMTOSCQueryClientDelegate.h"

@interface IMTOSCQueryClient : NSObject <GCDAsyncSocketDelegate> {

    GCDAsyncSocket *socket;
    
    NSString *host;
    int port;
    
    dispatch_queue_t queue;
    
    // store request for pipelining (not done yet)
    NSMutableArray *requests;
}

@property (weak) id<IMTOSCQueryClientDelegate> delegate;

- (instancetype)initWithHost:(NSString *)host onPort:(int)port;

- (void)queryFullAddressSpace;
- (void)queryAddress:(NSString *)address;


- (void)disconnect;

@end
