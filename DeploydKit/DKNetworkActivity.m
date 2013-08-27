//
//  DKNetworkActivity.m
//  DeploydKit
//
//  Created by Denis Berton
//  Copyright (c) 2012 clooket.com. All rights reserved.
//
//  DeploydKit is based on DataKit (https://github.com/eaigner/DataKit)
//  Created by Erik Aigner
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKNetworkActivity.h"
#import <libkern/OSAtomic.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "AFNetworking.h"

@implementation DKNetworkActivity

static int32_t kDKNetworkActivityCount = 0;

+ (void)updateNetworkActivityStatus {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = (kDKNetworkActivityCount > 0);
}

+ (void)begin {
#ifdef AFNetworking_NOT_AVAILABLE
  OSAtomicIncrement32(&kDKNetworkActivityCount);
  [self updateNetworkActivityStatus];
#else // AFNetworking_NOT_AVAILABLE
	[[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
#endif // AFNetworking_NOT_AVAILABLE
}

+ (void)end {
#ifdef AFNetworking_NOT_AVAILABLE
  OSAtomicDecrement32(&kDKNetworkActivityCount);

  // Delay update a little to avoid flickering
  double delayInSeconds = 0.2;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [self updateNetworkActivityStatus];
  });
#else // AFNetworking_NOT_AVAILABLE
	[[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
#endif // AFNetworking_NOT_AVAILABLE
}

+ (NSInteger)activityCount {
  return kDKNetworkActivityCount;
}

@end
