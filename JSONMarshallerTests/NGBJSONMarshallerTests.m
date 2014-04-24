//
//  NGBJSONMarshallerTests.m
//  JSONMarshaller
//
//  Created by Jens Ravens on 24/04/14.
//  Copyright (c) 2014 nerdgeschoss GmbH. All rights reserved.
//

#import "NGBTestCase.h"

#import "NGBMarshaller.h"

@interface NGBJSONMarshallerTests : NGBTestCase

@end

@implementation NGBJSONMarshallerTests

#pragma mark - Tests

- (void)testInsertingObject
{
    [[self createMarshaller] createObjectWithID:@"some-id" fields:@{@"title":@"testname"}];
    
    NSManagedObject* product = [self getFirstObject];
    XCTAssertEqualObjects([product valueForKey:@"serverID"], @"some-id", @"object should be created");
    XCTAssertEqualObjects([product valueForKey:@"title"], @"testname", @"object should be created with fields");
    XCTAssertEqual([self getAllObjects].count, 1, @"there should exactly be one object");
}

- (void)testUpdatingObject
{
    NSString* serverID = @"some-id";
    NSString* name = @"some name";
    NSManagedObject* product = [self createWithServerID:serverID];
    
    [[self createMarshaller] updateObject:product fields:@{@"title":name}];
    
    XCTAssertEqualObjects([product valueForKey:@"title"], name, @"name value should be updated");
}

- (void)testUpdatingObjectByID
{
    NSString* serverID = @"some-id";
    NSString* name = @"some name";
    NSManagedObject* product = [self createWithServerID:serverID];
    
    [[self createMarshaller] updateObjectWithID:serverID fields:@{@"title":name}];
    
    XCTAssertEqualObjects([product valueForKey:@"title"], name, @"name value should be updated");
}

- (void)testUpsertingObjectForExistingObject
{
    NSString* serverID = @"some-id";
    NSString* name = @"some name";
    NSManagedObject* product = [self createWithServerID:serverID];
    
    [[self createMarshaller] upsertObjectWithID:serverID fields:@{@"title":name}];
    
    XCTAssertEqualObjects([product valueForKey:@"title"], name, @"name value should be updated");
    XCTAssertEqual([self getAllObjects].count, 1, @"there should exactly be one object");
}

- (void)testUpsertingObjectForNonexistingObject
{
    NSString* serverID = @"some-id";
    NSString* name = @"some name";
    
    NSManagedObject* product = [[self createMarshaller] upsertObjectWithID:serverID fields:@{@"title":name}];
    
    XCTAssertEqualObjects([product valueForKey:@"title"], name, @"name value should be updated");
    XCTAssertEqual([self getAllObjects].count, 1, @"there should exactly be one object");
}

- (void)testDeletingObject
{
    NSString* serverID = @"some-id";
    [self createWithServerID:serverID];
    
    BOOL returnValue = [[self createMarshaller] deleteObjectWithID:serverID];
    
    XCTAssertTrue(returnValue, @"deleting should be marked as success");
    XCTAssertEqual([self getAllObjects].count, 0, @"there should be no objects left");
}

- (void)testDeletingNonExistingObject
{
    NSString* serverID = @"some-id";
    
    BOOL returnValue = [[self createMarshaller] deleteObjectWithID:serverID];
    
    XCTAssertFalse(returnValue, @"deleting should fail if no object is present");
    XCTAssertEqual([self getAllObjects].count, 0, @"there should be no objects left");
}

#pragma mark - Convenience

- (NGBMarshaller*)createMarshaller
{
    return [[NGBMarshaller alloc] initWithEntity:self.entityDescription context:self.context];
}


@end
