//
//  AppDelegate.h
//  OSCQueryTest
//
//  Created by Tamas Nagy on 10/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OSCQueryServer.h"
#import "OSCQueryClient.h"
#import "OSCQueryClientDelegate.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, OSCQueryClientDelegate> {
    
    NSMutableArray *detectedServers;
    
    OSCQueryServer *testServer1;
    OSCQueryServer *testServer2;
    
    NSNetServiceBrowser *serviceBrowser;
    
    dispatch_queue_t serversQueue;
    
    OSCQueryClient *client;

    NSMutableDictionary *addressSpaceDict;
    NSMutableDictionary *fullPathesDict;
    
    NSString *currentAction;
}

@property (weak) IBOutlet NSTableView *serversTableView;
@property (weak) IBOutlet NSTableView *addressSpaceTableView;
@property (unsafe_unretained) IBOutlet NSTextView *logView;

- (IBAction)requestData:(id)sender;
@end

