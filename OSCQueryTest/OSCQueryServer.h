//
//  OSCQueryServer.h
//  OSCQueryTest
//
//  Created by Tamas Nagy on 10/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

//
// An OSCQueryServer instance should not be used from multiple threads at the same time
//
//
#import <Foundation/Foundation.h>
#import "OSCQueryDefinitions.h"
#import "GCDAsyncSocket.h"
#import "OSCQueryHTTPHeader.h"

@interface OSCQueryServer : NSObject <GCDAsyncSocketDelegate>  {
    
    GCDAsyncSocket *socket;
    
    NSNetService *netService;
    
    // clients related
    NSMutableArray *clients;

    dispatch_queue_t queue;
    
    NSMutableDictionary *oscAddressSpace;
    NSString *rootOSCAddress;
}

@property (copy) NSString *name;

- (instancetype)initServerWithName:(NSString *)name onPort:(int)port withRootAddress:(NSString *)root;

// create and address with the minimum configuration
- (void)addOSCAddress:(NSString *)address withDescription:(NSString *)description;


- (void)setType:(NSString *)type forAddress:(NSString *)address;
- (void)setRangeWithMin:(NSNumber *)min max:(NSNumber *)max forAddress:(NSString *)address;

@end
