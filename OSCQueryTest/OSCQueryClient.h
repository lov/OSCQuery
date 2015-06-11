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

@interface OSCQueryClient : NSObject <GCDAsyncSocketDelegate> {

    GCDAsyncSocket *socket;
    
    NSString *host;
    int port;
}

@property (strong) NSNotificationCenter *clientNotificationCenter;

- (instancetype)initWithHost:(NSString *)host onPort:(int)port;

- (void)queryFullAddressSpace;

- (void)disconnect;

@end