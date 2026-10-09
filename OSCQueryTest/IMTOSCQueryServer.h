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
@import Foundation;
#import <OSCQuery/IMTOSCQueryHTMLContentProvider.h>

NS_ASSUME_NONNULL_BEGIN

@class GCDAsyncSocket;

/// Supplies the complete Bonjour service label, independently of the server's display name.
///
/// Called synchronously when creating an advertisement. collisionIndex starts at 1 and
/// increases after a name collision. Include any desired port and collision suffix in the
/// returned label, and keep its complete UTF-8 representation within Bonjour's 63-byte limit.
/// For example, the second attempt might return "Playback:8000 (2)".
typedef NSString * _Nonnull (^IMTOSCQueryServiceNameProvider)(int port, NSUInteger collisionIndex);

/// Reports failure to start the listener or publish the Bonjour advertisement.
///
/// Listener startup failures are reported synchronously during initialization. Bonjour
/// failures arrive later on the publishing thread's run loop. Collisions are retried using
/// the name provider and are not reported as failures.
typedef void (^IMTOSCQueryPublicationErrorHandler)(NSError *error);

@interface IMTOSCQueryServer : NSObject <NSNetServiceDelegate>   {
    
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

// if a HMTL content provider is available, then this class will provide HTML data when the server is visited from a web browser (so when a User-Agent field is exist)
@property (weak, nullable) id<IMTOSCQueryHTMLContentProvider> htmlContentProvider;

// creates the server
- (nullable instancetype)initServerWithName:(NSString *)name onPort:(int)port withRootAddress:(NSString *)root;

/// Creates a server with independent display and Bonjour names and optional failure reporting.
///
/// name remains the complete HOST_INFO name. Copies both blocks. A nil provider preserves
/// the original "name:port" advertisement and automatic Bonjour renaming; a nil handler
/// leaves failures in the existing log without a callback. Returns nil if the name or root
/// is empty or the listener cannot start. Use the server from one thread with a running run
/// loop for Bonjour callbacks.
- (nullable instancetype)initServerWithName:(NSString *)name
                                     onPort:(int)port
                            withRootAddress:(NSString *)root
                        serviceNameProvider:(nullable IMTOSCQueryServiceNameProvider)provider
                    publicationErrorHandler:(nullable IMTOSCQueryPublicationErrorHandler)errorHandler;

// creates an address with the minimum configuration
- (void)addOSCAddress:(NSString *)address withDescription:(nullable NSString *)description;

// creates an address with settings
- (void)addOSCAddress:(NSString *)address
               ofType:(NSString *)type
       inRangeWithMin:(nullable NSNumber *)min
                  max:(nullable NSNumber *)max
      withDescription:(nullable NSString *)description;

// removes the given address with all sub-commands
- (void)removeOSCAddress:(NSString *)address;

// set values for addresses
- (void)setType:(NSString *)type forAddress:(NSString *)address;
- (void)setRangeWithMin:(nullable NSNumber *)min max:(nullable NSNumber *)max forAddress:(NSString *)address;

- (void)stop;
- (void)restart;

- (void)removeResources;
@end

NS_ASSUME_NONNULL_END
