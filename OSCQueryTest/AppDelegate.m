//
//  AppDelegate.m
//  IMTOSCQueryTest
//
//  Created by Tamas Nagy on 10/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#import "AppDelegate.h"
#include <arpa/inet.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)awakeFromNib {

    detectedServers = [NSMutableArray new];
    
    serversQueue =  dispatch_queue_create("com.imimot.serversQueue", DISPATCH_QUEUE_SERIAL);

    client = nil;
    
    addressSpaceDict = [NSMutableDictionary new];
    fullPathesDict = [NSMutableDictionary new];
    
    
    [[self serversTableView] setDoubleAction:@selector(serverSelected)];
    [[self addressSpaceTableView] setDoubleAction:@selector(addressSelected)];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    

    serviceBrowser = [[NSNetServiceBrowser alloc] init];
    [serviceBrowser setDelegate:self];
    [serviceBrowser searchForServicesOfType:@"_oscjson._tcp." inDomain:@""];
    
    testServer1 = [[IMTOSCQueryServer alloc] initServerWithName:@"TestQueryServer1" onPort:3333 withRootAddress:@"/"];
    testServer2 = [[IMTOSCQueryServer alloc] initServerWithName:@"TestQueryServer2" onPort:6000 withRootAddress:@"/test"];
    
   // [testServer1 addOSCAddress:@"/test/layer/position/x" withDescription:@"Layer Position on the X axis"];
   // [testServer1 setType:IMTOSCQuery_TYPE_FLOAT forAddress:@"/layer/position/x"];
   // [testServer1 setRangeWithMin:[NSNumber numberWithFloat:0] max:[NSNumber numberWithFloat:1] forAddress:@"/layer/position/x"];

    //[testServer1 addOSCAddress:@"/test/layer/position/y" withDescription:@"Layer Position on the Y axis"];
    //[testServer1 addOSCAddress:@"/test/composition/rotate/z" withDescription:@"Composition Rotate on the Z axis"];
    //[testServer1 setRangeWithMin:[NSNumber numberWithFloat:0] max:[NSNumber numberWithFloat:1] forAddress:@"/layer/position/y"];
    
    [testServer1 addOSCAddress:@"/ping" withDescription:@"Ping"];
    [testServer2 addOSCAddress:@"/1/opacity/fader" withDescription:@"Fader opacity on Layer 1"];
    //[testServer1 addOSCAddress:@"/test/1/fader" withDescription:@"Fader on Layer 1"];
    //[testServer1 setType:IMTOSCQuery_TYPE_FLOAT forAddress:@"/test/1/fader"];
    //[testServer1 setRangeWithMin:[NSNumber numberWithFloat:0] max:[NSNumber numberWithFloat:1] forAddress:@"/test/1/fader"];
    //[testServer1 setType:IMTOSCQuery_TYPE_FLOAT forAddress:@"/1/opacity/fader"];

    /*
    // measuring performance
    NSDate *now = [NSDate date];
    for (int i=0;i<10000;i++) {
 
        NSString *address = [NSString stringWithFormat: @"/test/something/%d/foo",i];
        
        [testServer1 addOSCAddress:address withDescription:@"test address"];
        [testServer1 setType:OSC_TYPE_FLOAT forAddress:address];
        [testServer1 setRangeWithMin:[NSNumber numberWithFloat:0] max:[NSNumber numberWithFloat:1] forAddress:address];
        [testServer1 setRangeWithMin:[NSNumber numberWithFloat:0] max:[NSNumber numberWithFloat:1] forAddress:address];

    }
    NSLog(@"10.000 addresses created in ~%fs", [[NSDate date] timeIntervalSinceDate:now]);
    */
    
    
    client = nil;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark Handling servers

- (void)serverSelected {
    
    if (client) {
        
        [client disconnect];
        
        addressSpaceDict = nil;

    }
    
    
    dispatch_sync(serversQueue, ^{
        // start resolving the address, and try to connect when its ready
        [[detectedServers objectAtIndex:[[self serversTableView] clickedRow]] resolveWithTimeout:1.0f];
    });
    
    
}

- (void)sortServersList {

    dispatch_sync(serversQueue, ^{
        [detectedServers sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            
            NSString *name1 = [obj1 name];
            NSString *name2 = [obj2 name];
            
            return [name1 compare:name2];
        }];
    });

}

#pragma mark Get Address space info

- (void)addressSelected {
    
   // NSLog(@"addressSelected");
    
    __block NSString *path = @"";
    
    dispatch_sync(serversQueue, ^{
       path = [[fullPathesDict allKeys] objectAtIndex:[[self addressSpaceTableView] clickedRow]];
    });
    
    [client queryAddress:path];
}

#pragma mark TableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    
    __block NSInteger count = 0;
    
    dispatch_sync(serversQueue, ^{
        
        if ([tableView isEqualTo:[self serversTableView]]) {
        
            count = [detectedServers count];

        } else {
            
            count = [fullPathesDict count];
        }
    });
    
    return count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    if ([tableView isEqualTo:[self serversTableView]]) {
        
        if ([detectedServers count]>0) {
            
            __block id obj = nil;
            
            dispatch_sync(serversQueue, ^{
                
                
                obj = [[detectedServers objectAtIndex:row] name];
                
                
            });
            
            
            return obj;
        }

    } else {
        
        if ([fullPathesDict count]>0) {
            
            __block id obj = nil;
            
            dispatch_sync(serversQueue, ^{
                
                
                obj = [[fullPathesDict allKeys] objectAtIndex:row];
                
                
            });
            
            
            return obj;
        }

    }

    
    return nil;
}



#pragma mark Net Service Browser

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    
    dispatch_sync(serversQueue, ^{
        [aNetService setDelegate:self];
        [detectedServers addObject:aNetService];
    });
    
    [self sortServersList];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[self serversTableView] reloadData];
    });
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {

    dispatch_sync(serversQueue, ^{
        [aNetService setDelegate:nil];
        [detectedServers removeObject:aNetService];
    });

    [self sortServersList];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[self serversTableView] reloadData];
    });

}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {

    NSLog(@"netServiceDidResolveAddress...");
    
    // code part from http://stackoverflow.com/questions/938521/iphone-bonjour-nsnetservice-ip-address-and-port/4976808#4976808
    char addressBuffer[INET6_ADDRSTRLEN];
    
    for (NSData *data in sender.addresses)
    {
        memset(addressBuffer, 0, INET6_ADDRSTRLEN);
        
        typedef union {
            struct sockaddr sa;
            struct sockaddr_in ipv4;
            struct sockaddr_in6 ipv6;
        } ip_socket_address;
        
        ip_socket_address *socketAddress = (ip_socket_address *)[data bytes];
        
        if (socketAddress && (socketAddress->sa.sa_family == AF_INET || socketAddress->sa.sa_family == AF_INET6))
        {
            const char *addressStr = inet_ntop(
                                               socketAddress->sa.sa_family,
                                               (socketAddress->sa.sa_family == AF_INET ? (void *)&(socketAddress->ipv4.sin_addr) : (void *)&(socketAddress->ipv6.sin6_addr)),
                                               addressBuffer,
                                               sizeof(addressBuffer));
            
            int port = ntohs(socketAddress->sa.sa_family == AF_INET ? socketAddress->ipv4.sin_port : socketAddress->ipv6.sin6_port);
            
            if (addressStr && port)
            {

                
                client = [[IMTOSCQueryClient alloc] initWithHost:[NSString stringWithUTF8String:addressStr] onPort:port];
                
                if (client) {
                    
                    [client setDelegate:self];
                    
                    [self writeToLog:[NSString stringWithFormat:@"client created and connected to %s:%d", addressStr,port]];
                    
                    
                    return;
                    
                } else {
                    
                    [self writeToLog:[NSString stringWithFormat:@"client is nil"]];

                }
                 
            } else {
                
                [self writeToLog:[NSString stringWithFormat:@"addressStr && port is false"]];
                

            }
        } else {
            
            [self writeToLog:[NSString stringWithFormat:@"socketAddress problem"]];

        }
    }
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    
    [self writeToLog:@"cannot resolve address... \n"];
}

- (void)netServiceDidStop:(NSNetService *)sender {

    //
    // TODO: handle this
    //
    
    [self writeToLog:@"good bye, server... :( \n"];

}

#pragma mark Logging

- (void)writeToLog:(NSString *)log {
    
    [[[self logView] textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:[log stringByAppendingString:@"\n"] attributes:nil]];
    [[self logView] scrollRangeToVisible:NSMakeRange([[[self logView] string] length], 0)];

}


#pragma mark IMTOSCQuery delegate

- (void)replyReceived:(NSDictionary *)reply forRequest:(NSString *)request {
    
   // NSLog(@"reply received: %@ forRequest: %@", reply, request);
    
    NSDictionary *data = reply;
    
    if (data && request) {
    
        if ([request isEqualToString:@"/"]) {
        
            dispatch_sync(serversQueue, ^{
                [addressSpaceDict removeAllObjects];
                [fullPathesDict removeAllObjects];
            });
            
                //  NSLog(@"buildAddressSpaceDataWithDictionary: %@", data);

            // the root should be always one element, so [[data allKeys] firstObject] should be the root addresse
            [self buildAddressSpaceDataWithDictionary:data toDictionary:addressSpaceDict];
            
             // NSLog(@"addressSpaceDict: %@", addressSpaceDict);
            //      NSLog(@"fullPathesDict: %@", fullPathesDict);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self addressSpaceTableView] reloadData];
            });

        } else {
            
            // do nothing here yet, just logging out
            
        }
        
        
        [self writeToLog:[NSString stringWithFormat:@"======== REPLY ========\n%@\n========================", data]];
    }
}

- (void)errorReceived:(int)error forRequest:(NSString *)request {
    
    [self writeToLog:[NSString stringWithFormat:@"Error %d for request: %@\n========================", error, request]];
}

#pragma mark Misc

- (void)buildAddressSpaceDataWithDictionary:(NSDictionary *)srcDict toDictionary:(NSMutableDictionary *)targetDict {
    
    /*
    if ([srcDict isKindOfClass:[NSArray class]]) {
        
        [self buildAddressSpaceDataWithDictionary:[(NSArray *)srcDict firstObject] toDictionary:targetDict];
        
        return;
        
    }
    */
    NSDictionary *start = [srcDict objectForKey:IMTOSCQuery_CONTENTS];

    
    if ([start isKindOfClass:[NSArray class]]) {
        
        start = [(NSArray *)start firstObject];
        
       // NSLog(@"start: %@", [start className]);

    }
    
    if (start && [[start allKeys] count]>1) {
        
        for (NSString *current in [start allKeys]) {
        
            dispatch_sync(serversQueue, ^{
                [targetDict setObject:[NSMutableDictionary new] forKey:current];
            });
            
            
            [self buildAddressSpaceDataWithDictionary:[start objectForKey:current] toDictionary:[targetDict objectForKey:current]];
        }
        
    } else {
        
       // NSLog(@"srcdict: %@", srcDict);
        
        dispatch_sync(serversQueue, ^{
            [fullPathesDict setObject:srcDict forKey:[srcDict objectForKey:IMTOSCQuery_FULL_PATH]];
        });

    }
}

- (IBAction)requestData:(id)sender {
    
    NSString *request = [sender stringValue];
    
    if (request && [request length]>0) {
    
        [client queryAddress:request];

    } else {
        
        NSBeep();
    }
}

@end
