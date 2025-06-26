//
//  IMTOSCQueryHTMLProvider.h
//  OSCQueryTest
//
//  Created by Tamas Nagy on 2025. 06. 26..
//  Copyright © 2025 Imimot Kft. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IMTOSCQueryHTMLContentProvider <NSObject>

- (NSData *)htmlContentAsDataWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
