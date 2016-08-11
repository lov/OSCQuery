//
//  IMTOSCQueryClientDelegate.h
//  IMTOSCQueryTest
//
//  Created by Tamas Nagy on 12/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IMTOSCQueryClientDelegate <NSObject>

- (void)replyReceived:(NSDictionary *)reply forRequest:(NSString *)request;
- (void)errorReceived:(int)error forRequest:(NSString *)request;
@end
