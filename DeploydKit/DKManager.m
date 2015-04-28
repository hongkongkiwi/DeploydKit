//
//  DKManager.m
//  DeploydKit
//
//  Created by Denis Berton
//  Copyright (c) 2012 clooket.com. All rights reserved.
//
//  DeploydKit is based on DataKit (https://github.com/eaigner/DataKit)
//  Created by Erik Aigner
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

// TODO: We should change this to be from a global instance to be an instance that's passed to each object that's created. E.g. [DKEntity fileName: withManager: ]; that way we can support multi instance enviroments

#import "DKManager.h"
#import "DKRequest.h"
#import "DKReachability.h"
#import "EGOCache.h"

@interface DKManager()
@property (nonatomic, strong) DKReachability *reachability;
@end

@implementation DKManager

+ (DKManager *) sharedInstance {
    
    static DKManager *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DKManager alloc]init];
    });
    
    return instance;
}

- (DKManager *) init {
    if (self = [super init]) {
        self.dispatchQueue = dispatch_queue_create("DeploydKit queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void) setApiEndPoint:(NSString *)apiEndPoint {
    NSURL *ep = [NSURL URLWithString:apiEndPoint];
    if (![ep.scheme isEqualToString:@"https"]) {
      NSLog(@"\n\nWARNING: DeploydKit API endpoint not secured! "
            "It's highly recommended to use SSL (current scheme is '%@')\n\n",
            ep.scheme);
    }
    _apiEndPoint = apiEndPoint;

    // allocate a reachability object
    self.reachability = [DKReachability reachabilityWithHostname:ep.host];
    DKNetworkStatus internetStatus = [self.reachability currentReachabilityStatus];
    
    if (internetStatus == DKNotReachable) {
        self.internetReachable = NO;
    } else {
        self.internetReachable = YES;
    }
        
    // here we set up a NSNotification observer. The Reachability that caused the notification
    // is passed in the object parameter
    [[NSNotificationCenter defaultCenter] addObserver:[self class]
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    [self.reachability startNotifier];
}

- (NSURL *) endpointForMethod:(NSString *)method {
    return [NSURL URLWithString:[self.apiEndPoint stringByAppendingPathComponent:method]];
}

- (void)clearAllCachedResults{
  [[EGOCache globalCache] clearCache];
}

//Called by DKReachability whenever status changes.
+ (void)reachabilityChanged: (NSNotification* )note
{
    DKReachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass: [DKReachability class]]);
    DKNetworkStatus internetStatus = [curReach currentReachabilityStatus];
    if(internetStatus == DKNotReachable) {
        [DKManager sharedInstance].internetReachable = NO;
        return;
    }
    [DKManager sharedInstance].internetReachable = YES;
}

@end
