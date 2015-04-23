//
//  DKFileSaveTests.m
//  DeploydKit
//
//  Created by Denis Berton
//  Copyright (c) 2012 clooket.com. All rights reserved.
//
//  DeploydKit is based on DataKit (https://github.com/eaigner/DataKit)
//  Created by Erik Aigner
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKFileTests.h"
#import "DeploydKit.h"
#import "DKTests.h"

@implementation DKFileTests

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

- (NSData *)generateRandomDataWithLength:(NSUInteger)numBytes {
  NSMutableData *data = [NSMutableData new];
  NSData *startData = [@"DSTART!" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *endData = [@"DEND!" dataUsingEncoding:NSUTF8StringEncoding];
  NSUInteger plus = (startData.length + endData.length);
  numBytes = MAX(numBytes, plus) - plus;
  [data appendData:startData];
  for (int i=0; i<numBytes; i++) {
    UInt8 c = (UInt8)(rand() % 255);
    CFDataAppendBytes((__bridge CFMutableDataRef)data, &c, 1);
  }
  [data appendData:endData];
  return [NSData dataWithData:data];
}

- (void)testRandomData {
  NSInteger len = 1024;
  NSData *data = [self generateRandomDataWithLength:len];
  NSData *data2 = [self generateRandomDataWithLength:len];
  
  XCTAssertFalse([data isEqualToData:data2]);
}

- (void)testFileIntegrityAndLoad {
  NSError *error = nil;
  BOOL success = NO;
    
  [self createDefaultUserAndLogin];
    
  NSData *data = [self generateRandomDataWithLength:1024];//*1024];

  //Save file
  error = nil;    
  DKFile *file = [DKFile fileWithName:nil data:data]; //filename ignored, generated with uuid
  XCTAssertTrue(file.isVolatile);
  XCTAssertEqualObjects(data, file.data);
  success = [file save:&error];
  XCTAssertTrue(success);
  XCTAssertNil(error.localizedDescription);
  XCTAssertFalse(file.isVolatile);
  XCTAssertEqualObjects(data, file.data);
  NSString *fileName = file.name;
    
  //Check exists (YES)
  error = nil;
  BOOL exists = [DKFile fileExists:fileName error:&error];
  XCTAssertNil(error);
  XCTAssertNil(error.localizedDescription);
  XCTAssertTrue(exists);
  
  //Load file
  error = nil;
  DKFile *file2 = [DKFile fileWithName:fileName];
  NSData *data2 = [file2 loadData:&error];
    XCTAssertNil(error);
    XCTAssertNil(error.localizedDescription);
  XCTAssertTrue([data isEqualToData:data2]);
    
  //Delete file
  error = nil;
  success = [file2 delete];
  XCTAssertTrue(success);
    XCTAssertNil(error);
    XCTAssertNil(error.localizedDescription);
    
  //Check exists (NO)
  error = nil;
  exists = [DKFile fileExists:fileName error:&error];
    XCTAssertNil(error);
    XCTAssertNil(error.localizedDescription);
  XCTAssertFalse(exists);

  [self deleteDefaultUser];
}

@end
