//
//  DKFile.m
//  DeploydKit
//
//  Created by Denis Berton
//  Copyright (c) 2012 clooket.com. All rights reserved.
//
//  DeploydKit is based on DataKit (https://github.com/eaigner/DataKit)
//  Created by Erik Aigner
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKFile.h"
#import "DKManager.h"
#import "DKRequest.h"
#import "DKNetworkActivity.h"
#import "NSURLConnection+Timeout.h"
#import "EGOCache.h"
#import "NSString+Additions.h"

@interface DKFile ()
    @property (nonatomic, assign, readwrite) BOOL isVolatile;
    @property (nonatomic, assign, readwrite) BOOL isLoading;
    @property (nonatomic, copy, readwrite) NSString *name;
    @property (nonatomic, strong, readwrite) NSData *data;
@end

@implementation DKFile

+ (DKFile *)fileWithData:(NSData *)data {
    return [[self alloc] initWithName:nil data:data];
}

+ (DKFile *)fileWithName:(NSString *)name {
  return [[self alloc] initWithName:name data:nil];
}

+ (DKFile *)fileWithName:(NSString *)name data:(NSData *)data {
    return [[self alloc] initWithName:name data:data];
}

- (id)initWithName:(NSString *)name data:(NSData *)data {
  self = [self init];
  if (self) {
    self.data = data;
    self.name = name;
    self.isVolatile = YES;
    self.cachePolicy = DKCachePolicyIgnoreCache;
    self.maxCacheAge = [EGOCache globalCache].defaultTimeoutInterval;
  }
  return self;
}

+ (BOOL)fileExists:(NSString *)fileName {
  return [self fileExists:fileName error:NULL];
}

+ (BOOL)fileExists:(NSString *)fileName error:(NSError **)error {

  // Check for file name
  if (fileName.length == 0) {
        [NSException raise:NSInternalInconsistencyException
                    format:NSLocalizedString(@"Invalid filename", nil)];
        return NO;
  }
    
  // Send request synchronously
  DKRequest *request = [DKRequest request];
  request.cachePolicy = DKCachePolicyIgnoreCache;

  NSDictionary *requestDict = @{[DKManager sharedInstance].fileRecordFileNameProperty: fileName};
  NSMutableString * queryParams = [NSMutableString stringWithString:[DKManager sharedInstance].fileRecordCollection];
    
  NSError *requestError = nil;
  id results = [request sendRequestWithObject:requestDict method:@"query" entity:queryParams error:&requestError];
  if (requestError != nil) {
    if (error != nil) {
        *error = requestError;
    }
    return NO;
  }
   
  if ([results isKindOfClass:[NSArray class]]) {
    for (NSDictionary *objDict in results) {
        if ([objDict isKindOfClass:[NSDictionary class]]) {
                NSString *resultFileName = objDict[[DKManager sharedInstance].fileRecordFileNameProperty];
                return [fileName isEqualToString: resultFileName];
        }
    }
  }
    
  return NO;
}

+ (void)fileExists:(NSString *)fileName inBackgroundWithBlock:(void (^)(BOOL exists, NSError *error))block {
  block = [block copy];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
	dispatch_queue_t q = [NSThread isMainThread] ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
#else
	dispatch_queue_t q = dispatch_get_current_queue();
#endif
  dispatch_async([DKManager sharedInstance].dispatchQueue, ^{
    NSError *error = nil;
    BOOL exists = [self fileExists:fileName error:&error];
    if (block != NULL) {
      dispatch_async(q, ^{
        block(exists, error); 
      });
    }
  });
}

+ (BOOL)deleteFile:(NSString *)fileName error:(NSError **)error {
    // Create the request
    DKRequest *request = [DKRequest request];
    request.cachePolicy = DKCachePolicyIgnoreCache;
    
    NSDictionary *dict = @{};

    NSError *requestError = nil;
    [request sendRequestWithObject:dict method:@"delete" entity:[[DKManager sharedInstance].fileRecordCollection stringByAppendingPathComponent:fileName] error:&requestError];
    if (requestError != nil) {
        if (error != nil) {
            *error = requestError;
        }
        return NO;
    }
    return YES;
}

- (BOOL)delete {
  return [self delete:NULL];
}

- (BOOL)delete:(NSError **)error {
  return [[self class] deleteFile:self.name error:error];
}

- (void)deleteInBackgroundWithBlock:(void (^)(BOOL success, NSError *error))block {
  block = [block copy];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
	dispatch_queue_t q = [NSThread isMainThread] ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
#else
	dispatch_queue_t q = dispatch_get_current_queue();
#endif
  dispatch_async([DKManager sharedInstance].dispatchQueue, ^{
    NSError *error = nil;
    BOOL success = [self delete:&error];
    if (block != NULL) {
      dispatch_async(q, ^{
        block(success, error); 
      });
    }
  });
}

- (BOOL)saveSynchronous:(BOOL)saveSync //TODO: saveSync ignored
            resultBlock:(void (^)(BOOL success, NSError *error))resultBlock
                  error:(NSError **)error {
  // Check if data is set
  if (self.data.length == 0) {
    [NSException raise:NSInternalInconsistencyException format:NSLocalizedString(@"Cannot save file with no data set", nil)];
    return NO;
  }
    
  // Create url request
  NSString *ep = [[DKManager sharedInstance].apiEndPoint stringByAppendingPathComponent:[DKManager sharedInstance].s3bucketCollection];

  if (self.name.length > 0) {
      ep = [ep stringByAppendingPathComponent:self.name];
  }
    
  NSURL *URL = [NSURL URLWithString:ep];
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
  
  req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
  req.HTTPBody = self.data;
  req.HTTPMethod = @"POST";
  
  NSString *contentLen = [NSString stringWithFormat:@"%lu", (unsigned long)self.data.length];
  
  [req setValue:contentLen forHTTPHeaderField:@"Content-Length"];
  [req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
  
  // Log
  if ([DKManager sharedInstance].requestLoggingEnabled) {
    NSLog(@"[FILE] save '%@' (%lu bytes)", self.name, (unsigned long)self.data.length);
  }
  
  // Start network activity indicator
  self.isLoading = YES;
  [DKNetworkActivity begin];
  
  // Save synchronous
  NSError *reqError = nil;
  NSHTTPURLResponse *response = nil;
  NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response timeout:20.0 error:&reqError];
    
  // End network activity
  self.isLoading = NO;
  [DKNetworkActivity end];
    
  [DKRequest logData:data isOut:NO isCached:NO];
    
  // Parse response
  id resultObj = nil;
  NSError *JSONError = nil;
  // A successful operation must not always return a JSON body
  if (data.length > 0) {
    resultObj = [NSJSONSerialization JSONObjectWithData:data
                                                options:NSJSONReadingAllowFragments
                                                  error:&JSONError];
  }
  if (JSONError != nil) {   //TODO: check reqError
    [NSError writeToError:error
                     code:DKErrorInvalidResponse
              description:NSLocalizedString(@"Could not deserialize JSON response", nil)
                 original:JSONError];
  }
  if([resultObj isKindOfClass:[NSDictionary class]]){
    self.name = resultObj[[DKManager sharedInstance].fileRecordFileNameProperty];
    if(!self.name) return NO;
    self.isVolatile = NO;
    if(resultBlock) resultBlock(YES,nil);
    return YES;
  }
  else{
    if(resultBlock) resultBlock(NO,*error);
  }
  
  return NO;
}

- (BOOL)save {
  return [self save:NULL];
}

- (BOOL)save:(NSError **)error {
  return [self saveSynchronous:YES resultBlock:NULL error:error];
}

- (void)saveInBackgroundWithBlock:(void (^)(BOOL success, NSError *error))block {
  [self saveSynchronous:NO resultBlock:block error:NULL];
}


- (NSData *)loadSynchronous:(BOOL)loadSync //TODO: loadSync ignored
                resultBlock:(void (^)(BOOL success, NSData *data, NSError *error))resultBlock
                      error:(NSError **)error {
  // Check file name
  if (self.name.length == 0) {
    [NSException raise:NSInternalInconsistencyException
                format:NSLocalizedString(@"Invalid filename", nil)];
    return nil;
  }
  
  // Create url request
  NSString *ep = [[DKManager sharedInstance].apiEndPoint stringByAppendingPathComponent:[DKManager sharedInstance].s3bucketCollection];
  if (self.name.length > 0) {
    ep = [ep stringByAppendingPathComponent:self.name];
  }
  
  if (self.extraQueryParams && [self.extraQueryParams count] > 0) {
      ep = [ep stringByAppendingQueryParams:self.extraQueryParams];
  }
    
  NSURL *URL = [NSURL URLWithString:ep];
    
    if ([DKManager sharedInstance].requestLoggingEnabled) {
        NSLog(@"URL: %@", URL);
    }
    
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
  req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
  req.HTTPMethod = @"GET";  
  
  // Log
  if ([DKManager sharedInstance].requestLoggingEnabled) {
    NSLog(@"[FILE OUT] load name '%@'", self.name);
  }
  
  // Load sync
  NSError *reqError = nil;
  NSHTTPURLResponse *response = nil;
  NSData *result = nil;
  BOOL loadFromCache = NO;
    
  switch (self.cachePolicy) {
    case DKCachePolicyIgnoreCache:
        result = [self sendSynchronousRequest:req returningResponse:&response error:&reqError];
        break;
    case DKCachePolicyUseCacheElseLoad:
        if([req.HTTPMethod isEqualToString:@"GET"]){
            result = [[EGOCache globalCache] dataForKey:self.name];
            loadFromCache = YES;
        }
        if(!result){
            result = [self sendSynchronousRequest:req returningResponse:&response error:&reqError];
            loadFromCache = NO;
        }
        break;
    case DKCachePolicyUseCacheIfOffline:
        if(![DKManager sharedInstance].internetReachable && [req.HTTPMethod isEqualToString:@"GET"]){
            result = [[EGOCache globalCache] dataForKey:self.name];
            loadFromCache = YES;
        }else{
            result = [self sendSynchronousRequest:req returningResponse:&response error:&reqError];
        }
  }
    
  if ([DKManager sharedInstance].requestLoggingEnabled) {
    NSLog(@"[FILE IN%@] loaded size '%lu' byte",(loadFromCache ? @" CACHE" : @""),(unsigned long)(result?result.length:0));
  }
    
  if(!loadFromCache) {
    [[EGOCache globalCache] setData:result forKey:self.name withTimeoutInterval:self.maxCacheAge];
  }
    
  if (loadFromCache || response.statusCode == 200) {
    self.isVolatile = NO;
    if(resultBlock) resultBlock(YES,result,nil);
    return result;
  }
  else {
    if (error != NULL) {
        *error = reqError;
        if(resultBlock) resultBlock(NO,result,*error);
    }
  }

  return nil;
}

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error {
    // Start network activity indicator
    self.isLoading = YES;
    [DKNetworkActivity begin];
    
    NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:response timeout:20.0 error:error];
    
    // End network activity
    self.isLoading = NO;
    [DKNetworkActivity end];
    return data;
}

- (NSData *)loadData {
  return [self loadData:NULL];
}

- (NSData *)loadData:(NSError **)error {
  return [self loadSynchronous:YES resultBlock:NULL error:error];
}

- (void)loadDataInBackgroundWithBlock:(void (^)(BOOL success, NSData *data, NSError *error))block{
   [self loadSynchronous:NO resultBlock:block error:nil];
}

@end