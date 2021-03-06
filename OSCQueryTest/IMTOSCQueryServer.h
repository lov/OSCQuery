//
//  IMTOSCQueryServer.h
//  IMTOSCQueryTest
//
//  Created by Tamas Nagy on 10/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

//
// An IMTOSCQueryServer instance should not be used from multiple threads at the same time
//
//
#import <Foundation/Foundation.h>

@class GCDAsyncSocket;

@interface IMTOSCQueryServer : NSObject   {
    
    GCDAsyncSocket *socket;
    int _serverport;
    
    // for bonjour/zeroconf
    NSNetService *netService;
    
    // clients
    NSMutableArray *clients;

    // thread safety
    dispatch_queue_t queue;
    
    
    //
    NSMutableDictionary *oscAddressSpace;
    NSString *rootOSCAddress;
}

@property (copy) NSString *name;

// creates the server
- (instancetype)initServerWithName:(NSString *)name onPort:(int)port withRootAddress:(NSString *)root;

// creates an address with the minimum configuration
- (void)addOSCAddress:(NSString *)address withDescription:(NSString *)description;

// creates an address with settings
- (void)addOSCAddress:(NSString *)address ofType:(NSString *)type inRangeWithMin:(NSNumber *)min max:(NSNumber *)max  withDescription:(NSString *)description;


// removes the given address with all sub-commands
- (void)removeOSCAddress:(NSString *)address;

// set values for addresses
- (void)setType:(NSString *)type forAddress:(NSString *)address;
- (void)setRangeWithMin:(NSNumber *)min max:(NSNumber *)max forAddress:(NSString *)address;

- (void)stop;
- (void)restart;

- (void)removeResources;
@end
