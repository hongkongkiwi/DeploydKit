//
//  NSURLConnection+Timeout.m
//  DeploydKit
//
//  Created by Denis Berton
//  Copyright (c) 2012 clooket.com. All rights reserved.
//
//  DeploydKit is based on DataKit (https://github.com/eaigner/DataKit)
//  Created by Erik Aigner
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "NSURLConnection+Timeout.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "AFNetworking.h"

@implementation NSURLConnection (Timeout)

+ (dispatch_queue_t)timeoutLockQueue {
  static dispatch_queue_t queue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    queue = dispatch_queue_create("timeout lock queue", DISPATCH_QUEUE_SERIAL);
  });
  return queue;
}

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response timeout:(NSTimeInterval)timeout error:(NSError **)error {
  // DEVNOTE: Timeout interval is quirky
  // https://devforums.apple.com/thread/25282
  //
  // The minimum timeout for NSURLConnection is 120/240 seconds, so we need this workaround
  // to get the synchronous mechanism to cancel before that fixed minimum.
  //
  // Set a min timeout of 5 seconds
  //
  timeout = MAX(5.0, timeout);
  
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC);
  
  // Use a serial queue for locking, it should be faster than a explicit lock
  dispatch_queue_t lockQueue = [self timeoutLockQueue];
  
  __block BOOL finished = NO;
  __block NSData *data = nil;
  __block NSHTTPURLResponse *internalResponse = nil;
  __block NSError *internalErr = nil;
  __block dispatch_semaphore_t sema = dispatch_semaphore_create(0);
#ifndef AFNetworking_NOT_AVAILABLE
	AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
	[operation setCompletionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
#endif
	
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#ifdef AFNetworking_NOT_AVAILABLE
    data = [self sendSynchronousRequest:request returningResponse:&internalResponse error:&internalErr];
    
    // Use the locking queue
    dispatch_sync(lockQueue, ^{
      if (sema != NULL) {
        finished = YES;
        dispatch_semaphore_signal(sema);
      }
    });
#else // AFNetworking_NOT_AVAILABLE
	  [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		  internalResponse = operation.response;
		  internalErr = nil;
		  data = responseObject;
		  // Use the locking queue
		  dispatch_sync(lockQueue, ^{
			  if (sema != NULL) {
				  finished = YES;
				  dispatch_semaphore_signal(sema);
			  }
		  });
	  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		  internalResponse = operation.response;
		  internalErr = error;
		  // Use the locking queue
		  dispatch_sync(lockQueue, ^{
			  if (sema != NULL) {
				  finished = YES;
				  dispatch_semaphore_signal(sema);
			  }
		  });
	  }];
	  [operation start];
#endif // AFNetworking_NOT_AVAILABLE
  });
  dispatch_semaphore_wait(sema, popTime);
  
  // Release the semaphore inside the locking queue
  dispatch_sync(lockQueue, ^{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
	dispatch_release(sema);
#endif
    sema = NULL;
  });
  
  // Set error
  if (internalErr != nil) {
    NSLog(@"error: %@ (%li)", internalErr.localizedDescription, (long)internalErr.code);
    if (error != NULL) {
      *error = internalErr;
    }
  }

  // Return data and set response
  if (finished) {
    if (response != NULL) {
      *response = internalResponse;
    }
    return data;
  }
#ifndef AFNetworking_NOT_AVAILABLE
	[operation cancel];
#endif
	
  // If the request timed out, return an error
  if (error != NULL) {
    NSDictionary *infoDict = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Request timed out", nil)};
    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x100 userInfo:infoDict];
  }
  
  return nil;
}

@end
