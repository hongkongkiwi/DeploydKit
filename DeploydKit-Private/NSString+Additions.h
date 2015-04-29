//
//  NSURL+Additions.h
//  ContentDownloader
//
//  Created by Andy on 29/4/15.
//
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

- (NSString *) stringByAppendingQueryParam:(NSString *)param value:(NSString *)value;
- (NSString *) stringByAppendingQueryParams:(NSDictionary *)params;

@end
