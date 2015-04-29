//
//  NSURL+Additions.m
//  ContentDownloader
//
//  Created by Andy on 29/4/15.
//
//

#import "NSString+Additions.h"

@implementation NSString (Additions)

- (NSString *) stringByAppendingQueryParam:(NSString *)param value:(NSString *)value {
    if (![param length] || ![value length]) {
        return self;
    }
    
    if (value && [value length] > 0) {
        param = [NSString stringWithFormat:@"%@=%@", param, value];
    }
    
    return [NSString stringWithFormat:@"%@%@%@", self,
            [self rangeOfString:@"?"].length > 0 ? @"&" : @"?", param];
}

- (NSString *) stringByAppendingQueryParams:(NSDictionary *)params {
    NSString *fullQueryString = [self copy];
    
    for (NSString *key in params) {
        fullQueryString = [fullQueryString stringByAppendingQueryParam:key value:params[key]];
    }
    
    return fullQueryString;
}

@end