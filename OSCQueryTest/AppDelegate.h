//
//  AppDelegate.h
//  IMTOSCQueryTest
//
//  Created by Tamas Nagy on 10/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMTOSCQueryServer.h"
#import "IMTOSCQueryClient.h"
#import "IMTOSCQueryClientDelegate.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, IMTOSCQueryClientDelegate> {
    
    NSMutableArray *detectedServers;
    
    IMTOSCQueryServer *testServer1;
    IMTOSCQueryServer *testServer2;
    
    NSNetServiceBrowser *serviceBrowser;
    
    dispatch_queue_t serversQueue;
    
    IMTOSCQueryClient *client;

    NSMutableDictionary *addressSpaceDict;
    NSMutableDictionary *fullPathesDict;
    
}

@property (weak) IBOutlet NSTableView *serversTableView;
@property (weak) IBOutlet NSTableView *addressSpaceTableView;
@property (unsafe_unretained) IBOutlet NSTextView *logView;

// manual request
- (IBAction)requestData:(id)sender;

@end

