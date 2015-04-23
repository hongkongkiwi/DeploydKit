//
//  DKEntityTests.m
//  DeploydKit
//
//  Created by Denis Berton
//  Copyright (c) 2012 clooket.com. All rights reserved.
//
//  DeploydKit is based on DataKit (https://github.com/eaigner/DataKit)
//  Created by Erik Aigner
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKEntityTests.h"
#import "DeploydKit.h"
#import "DKEntity-Private.h"
#import "DKTests.h"

@implementation DKEntityTests

- (void)setUp {
  [DKManager setAPIEndpoint:kDKEndpoint];
  [DKManager setRequestLogEnabled:YES];
}

-(void)createDefaultUserAndLogin {
    NSError *error = nil;
    BOOL success = NO;
    
    //Insert user (SignUp)
    DKEntity *userObject = [DKEntity entityWithName:kDKEntityTestsUser];
    [userObject setObject:@"user_1" forKey:kDKEntityUserName];
    [userObject setObject:@"password_1" forKey:kDKEntityUserPassword];
    success = [userObject save:&error];
    XCTAssertNil(error, @"first insert should not return error, did return %@", error);
    XCTAssertTrue(success, @"first insert should have been successful (return YES)");
    
    //Login user
    error = nil;
    success = [userObject login:&error username:@"user_1" password:@"password_1"];
    XCTAssertNil(error, @"login should not return error, did return %@", error);
    XCTAssertTrue(success, @"login should have been successful (return YES)");
}

-(void) deleteDefaultUser{
    NSError *error = nil;
    BOOL success = NO;
    
    //Logged user
    DKEntity *userObject = [DKEntity entityWithName:kDKEntityTestsUser];
    success = [userObject loggedUser:&error];
    XCTAssertNil(error, @"user logged should not return error, did return %@", error);
    XCTAssertTrue(success, @"user logged should be logged (return YES)");
    
    //Delete user
    error = nil;
    success = [userObject delete:&error];
    XCTAssertNil(error, @"delete should not return error, did return %@", error);
    XCTAssertTrue(success, @"delete should have been successful (return YES)");
}

- (void)testUserAuth {
  NSError *error = nil;
  BOOL success = NO;
 
  [self createDefaultUserAndLogin];

  //Logged user
  DKEntity *userObject = [DKEntity entityWithName:kDKEntityTestsUser];
  success = [userObject loggedUser:&error];
  XCTAssertNil(error, @"user logged should not return error, did return %@", error);        
  XCTAssertTrue(success, @"user logged should be logged (return YES)");
    
  //Log out user
  error = nil;
  success = [userObject logout:&error];
  XCTAssertNil(error, @"logout should not return error, did return %@", error);    
  XCTAssertTrue(success, @"logout should have been successful (return YES)");
    
  //Logged user
  error = nil;
  success = [userObject loggedUser:&error];
  XCTAssertNotNil(error, @"user logged should return error, did return %@", error);
  XCTAssertFalse(success, @"user logged shouldn't be logged (return NO)");  
    
  //Delete user
  error = nil;
  success = [userObject delete:&error];
  XCTAssertNotNil(error, @"delete not logged should return error, did return %@", error);
  XCTAssertFalse(success, @"delete shouldn't have been successful (return NO)");

  //Login user
  error = nil;
  success = [userObject login:&error username:@"user_1" password:@"password_1"];
  XCTAssertNil(error, @"login should not return error, did return %@", error);        
  XCTAssertTrue(success, @"login should have been successful (return YES)");
    
  [self deleteDefaultUser];
}

- (void)testObjectCRUD {
  NSError *error = nil;
  BOOL success = NO;
    
  [self createDefaultUserAndLogin];  
    
  //Insert post
  DKEntity *postObject = [DKEntity entityWithName:kDKEntityTestsPost];
  [postObject setObject:@"My first post" forKey:kDKEntityTestsPostText];
  success = [postObject save:&error];
  XCTAssertNil(error, @"post insert should not return error, did return %@", error);
  XCTAssertTrue(success, @"post insert should have been successful (return YES)");
  
  NSUInteger mapCount = postObject.resultMap.count;
  XCTAssertEqual(mapCount, (NSUInteger)4, @"result map should have 4 elements, has %i", mapCount);
  
  NSString *userId = [postObject objectForKey:kDKEntityIDField];
  NSString *text = [postObject objectForKey:kDKEntityTestsPostText];

  XCTAssertTrue(userId.length > 0, @"result map should have field 'id'");
  XCTAssertEqualObjects(text, @"My first post", @"result map should have name field set to 'My first post', is '%@'", text);
  
  NSTimeInterval createdAt = postObject.createdAt.timeIntervalSince1970;
  NSTimeInterval createdNow = [[NSDate date] timeIntervalSince1970];
  NSString *creatorId = [postObject objectForKey:kDKEntityIDField];
    
  XCTAssertEqualWithAccuracy(createdAt, createdNow, 1.0);
  XCTAssertEqualObjects(userId, creatorId, @"result map should have the same creatorIs as is', is '%@'", creatorId);
    
  //Update post
  error = nil;    
  [postObject setObject:@"My first post udpated" forKey:kDKEntityTestsPostText];
  NSArray * sharedArray = @[@"user_2",@"user_3"];
  [postObject setObject:sharedArray forKey:kDKEntityTestsPostSharedTo];
  success = [postObject save:&error];
  XCTAssertNil(error, @"update should not return error, did return %@", error);
  XCTAssertTrue(success, @"update should have been successful (return YES)");
  
  mapCount = postObject.resultMap.count;
  XCTAssertEqual(mapCount, (NSUInteger)4, @"result map should have 6 elements, has %i", mapCount);
  
  userId = [postObject objectForKey:kDKEntityIDField];
  text = [postObject objectForKey:kDKEntityTestsPostText];
  sharedArray = [postObject objectForKey:kDKEntityTestsPostSharedTo];
    
  XCTAssertTrue(userId.length > 0, @"result map should have field 'id'");
  XCTAssertEqualObjects(text, @"My first post udpated", @"result map should have name field set to 'My first post udpated', is '%@'", text);
   
  NSTimeInterval updatedAt = postObject.updatedAt.timeIntervalSince1970;
  NSTimeInterval updatedNow = [[NSDate date] timeIntervalSince1970];
  XCTAssertEqualWithAccuracy(updatedAt, updatedNow, 1.0);

  //Refresh post
  error = nil;
  NSString *refreshField = [postObject objectForKey:kDKEntityTestsPostText];    
  [postObject setObject:@"My post unsaved" forKey:kDKEntityTestsPostText];    

  success = [postObject refresh:&error];
  XCTAssertNil(error, @"refresh should not return error, did return %@", error);
  XCTAssertTrue(success, @"refresh should have been successful (return YES)");
  
  mapCount = postObject.resultMap.count;
  XCTAssertEqual(mapCount, (NSUInteger)6, @"result map should have 5 elements, has %i", mapCount);
  XCTAssertEqualObjects([postObject objectForKey:kDKEntityTestsPostText], refreshField, @"result map should have the same creatorIs as is', is '%@'", [postObject objectForKey:kDKEntityTestsPostText]);

  //Delete post
  error = nil;
  success = [postObject delete:&error];
  XCTAssertNil(error, @"delete post should not return error, did return %@", error);
  XCTAssertTrue(success, @"delete post should have been successful (return YES)");
    
  [self deleteDefaultUser];
}

- (void)testObjectKeyIncrement {
  NSError *error = nil;
  BOOL success = NO;
  
  [self createDefaultUserAndLogin];    
    
  //Insert post
  DKEntity *postObject = [DKEntity entityWithName:kDKEntityTestsPost];
  [postObject setObject:@"My first post" forKey:kDKEntityTestsPostText];
  [postObject setObject:@3 forKey:kDKEntityTestsPostVisits];
  success = [postObject save:&error];
  XCTAssertNil(error); XCTAssertNil(error.localizedDescription); 
  XCTAssertTrue(success);
  XCTAssertEqual([[postObject objectForKey:kDKEntityTestsPostVisits] integerValue], (NSInteger)3);
  
  //Increment
  error = nil; 
  [postObject incrementKey:kDKEntityTestsPostVisits byAmount:@2];
  success = [postObject save:&error];
  XCTAssertEqual([[postObject objectForKey:kDKEntityTestsPostVisits] integerValue], (NSInteger)5);
    
  //Delete post
  error = nil;
  success = [postObject delete:&error];
  XCTAssertNil(error, @"delete post should not return error, did return %@", error);
  XCTAssertTrue(success, @"delete post should have been successful (return YES)");
    
  [self deleteDefaultUser];    
}

- (void)testObjectPush {
  NSError *error = nil;
  BOOL success = NO;
  
  [self createDefaultUserAndLogin];  
    
  //Insert post
  DKEntity *postObject = [DKEntity entityWithName:kDKEntityTestsPost];
  [postObject setObject:@[@"user_2"] forKey:kDKEntityTestsPostSharedTo];  
  success = [postObject save:&error];
  XCTAssertTrue(success);
  XCTAssertNil(error); XCTAssertNil(error.localizedDescription); 
  
  //Push object
  error = nil;    
  [postObject pushObject:@"user_3" forKey:kDKEntityTestsPostSharedTo];
  success = [postObject save:&error];
  XCTAssertTrue(success);
  XCTAssertNil(error); XCTAssertNil(error.localizedDescription); 
  NSArray *list = [postObject objectForKey:kDKEntityTestsPostSharedTo];
  NSArray *comp = @[@"user_2", @"user_3"];
  XCTAssertEqualObjects(list, comp);

  //Push all objects    
  error = nil;    
  [postObject pushAllObjects:@[@"user_4", @"user_5"] forKey:kDKEntityTestsPostSharedTo];
  success = [postObject save:&error];
  XCTAssertTrue(success);
  XCTAssertNil(error); XCTAssertNil(error.localizedDescription); 
  list = [postObject objectForKey:kDKEntityTestsPostSharedTo];
  comp = @[@"user_2", @"user_3", @"user_4", @"user_5"];
  XCTAssertEqualObjects(list, comp);
  
  //Delete post
  error = nil;
  success = [postObject delete:&error];
  XCTAssertNil(error, @"delete post should not return error, did return %@", error);
  XCTAssertTrue(success, @"delete post should have been successful (return YES)");
    
  [self deleteDefaultUser];    
}

- (void)testObjectPull {
  NSError *error = nil;
  BOOL success = NO;
    
  [self createDefaultUserAndLogin];  
    
  //Insert post
  DKEntity *postObject = [DKEntity entityWithName:kDKEntityTestsPost];
  NSMutableArray *values = [NSMutableArray arrayWithObjects:@"a", @"b", @"b", @"c", @"d", @"d", nil];    
  [postObject setObject:values forKey:kDKEntityTestsPostSharedTo];
  success = [postObject save:&error];
  XCTAssertTrue(success);
  XCTAssertNil(error); XCTAssertNil(error.localizedDescription); 
  
  //Pull object
  error = nil;
  [postObject pullObject:@"b" forKey:kDKEntityTestsPostSharedTo];
  success = [postObject save:&error];
  XCTAssertTrue(success);
  XCTAssertNil(error); XCTAssertNil(error.localizedDescription); 
  NSArray *list = [postObject objectForKey:kDKEntityTestsPostSharedTo];
  [values removeObject:@"b"];    
  XCTAssertEqualObjects(values, list);
  
  //Pull all objects
  error = nil;
  [postObject pullAllObjects:@[@"c", @"d"] forKey:kDKEntityTestsPostSharedTo];
  success = [postObject save:&error];
  XCTAssertTrue(success);
  XCTAssertNil(error); XCTAssertNil(error.localizedDescription); 
  [values removeObject:@"c"];
  [values removeObject:@"d"];
  list = [postObject objectForKey:kDKEntityTestsPostSharedTo];
  XCTAssertEqualObjects(values, list);

  //Delete post
  error = nil;
  success = [postObject delete:&error];
  XCTAssertNil(error, @"delete post should not return error, did return %@", error);
  XCTAssertTrue(success, @"delete post should have been successful (return YES)");
    
  [self deleteDefaultUser];    
}
/*
- (void)testObjectAddToSet {
    NSError *error = nil;
    BOOL success = NO;
    
    [self createDefaultUserAndLogin];
    
    //Insert post
    DKEntity *postObject = [DKEntity entityWithName:kDKEntityTestsPost];
    NSMutableArray *values = [NSMutableArray arrayWithObjects:@"b", nil];
    [postObject setObject:values forKey:kDKEntityTestsPostSharedTo];
    success = [postObject save:&error];
    STAssertTrue(success, nil);
    STAssertNil(error, error.description);
    
    //Add to set (NOT WORK, NOT DOCUMENTED IN DEPLOYD 0.6.9v, MAY WORK IN FUTURE VERSIONS)
    error = nil;
    [postObject addObjectToSet:@"d" forKey:kDKEntityTestsPostSharedTo];
    [postObject addAllObjectsToSet:[NSArray arrayWithObjects:@"a", @"b", @"c", nil] forKey:kDKEntityTestsPostSharedTo];
    [postObject addObjectToSet:@"1" forKey:kDKEntityTestsPostLocation];
    success = [postObject save:&error];
    STAssertTrue(success, nil);
    STAssertNil(error, error.description);    
    NSArray *list = [postObject objectForKey:kDKEntityTestsPostSharedTo];
    NSArray *comp = [NSArray arrayWithObjects:@"b", @"d", @"a", @"c", nil];
    STAssertEqualObjects(list, comp, nil);
    list = [postObject objectForKey:kDKEntityTestsPostLocation];
    comp = [NSArray arrayWithObjects:@"1", nil];
    STAssertEqualObjects(list, comp, nil);
        
    //Delete post
    error = nil;
    success = [postObject delete:&error];
    STAssertNil(error, @"delete post should not return error, did return %@", error);
    STAssertTrue(success, @"delete post should have been successful (return YES)");
    
    [self deleteDefaultUser];
}
*/ 
@end
