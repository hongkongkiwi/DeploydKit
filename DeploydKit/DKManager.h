//
//  DKManager.h
//  DeploydKit
//
//  Created by Denis Berton
//  Copyright (c) 2012 clooket.com. All rights reserved.
//
//  DeploydKit is based on DataKit (https://github.com/eaigner/DataKit)
//  Created by Erik Aigner
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//


/**
 The manager is used to configure common DeploydKit parameters
 */
@interface DKManager : NSObject

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@property (nonatomic, strong) NSString *apiEndPoint;
@property (nonatomic, strong) NSString *apiSecret;

@property (nonatomic, strong) NSString *s3bucketCollection;
@property (nonatomic, strong) NSString *fileRecordCollection;
@property (nonatomic, strong) NSString *fileRecordFileNameProperty;

@property (nonatomic, assign) BOOL requestLoggingEnabled;
@property (nonatomic, strong) NSString *sessionId;
@property (nonatomic, assign) NSTimeInterval maxCacheAge;
@property (nonatomic, assign) BOOL internetReachable;

+ (DKManager *) sharedInstance;

/** @name API Endpoint */

/**
 Returns the URL for the specified API method
 @param method The method name
 @return The method endpoint URL
 */
- (NSURL *) endpointForMethod:(NSString *)method;

/** @name Serial Request Queue */

/** @name Debug */

/** @name Controlling Caching Behavior (only used for GET requests)*/

/**
 Clears the cached results for all requests.
 */
- (void)clearAllCachedResults;

@end
