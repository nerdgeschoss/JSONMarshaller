//
//  NGBJSONMarshallerTests.m
//  JSONMarshaller
//
//  Created by Jens Ravens on 24/04/14.
//  Copyright (c) 2014 nerdgeschoss GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#import "NGBJSONMarshaller.h"

@interface NGBJSONMarshallerTests : XCTestCase

@property (nonatomic) NSManagedObjectModel* model;
@property (nonatomic) NSPersistentStoreCoordinator* coordinator;
@property (nonatomic) NSManagedObjectContext* context;
@property (nonatomic) NSEntityDescription* entityDescription;


@end

@implementation NGBJSONMarshallerTests

#pragma mark - Tests

- (void)testHealth
{
    XCTAssertNotNil(self.coordinator, @"coordinator should be initialized");
    XCTAssertNotNil(self.context, @"there should be a context");
    XCTAssertNotNil(self.entityDescription, @"there should be an entity in the specified context");
    XCTAssert([self getAllObjects].count == 0, @"there shouldnt be any objects before testing");
}

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

- (NGBJSONMarshaller*)createMarshaller
{
    return [[NGBJSONMarshaller alloc] initWithEntity:self.entityDescription context:self.context];
}

- (NSManagedObject*)createObject
{
    return [[NSManagedObject alloc] initWithEntity:self.entityDescription insertIntoManagedObjectContext:self.context];
}

- (NSManagedObject*)createWithServerID:(NSString*)serverID
{
    NSManagedObject* object = [self createObject];
    [object setValue:serverID forKey:@"serverID"];
    return object;
}

- (NSManagedObject*)getFirstObject
{
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:self.entityDescription.name];
    request.fetchLimit = 1;
    return [[self.context executeFetchRequest:request error:nil] firstObject];
}

- (NSArray*)getAllObjects
{
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:self.entityDescription.name];
    return [self.context executeFetchRequest:request error:nil];
}

#pragma mark - Core Data

- (NSEntityDescription*)entityDescription
{
    if (!_entityDescription){
        _entityDescription = [NSEntityDescription entityForName:@"Product" inManagedObjectContext:self.context];
    }
    return _entityDescription;
}

- (NSManagedObjectModel*)model
{
    if (!_model){
        _model = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    return _model;
}

- (NSPersistentStoreCoordinator*)coordinator
{
    if (!_coordinator){
        _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
        [_coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
    }
    return _coordinator;
}

- (NSManagedObjectContext*)context
{
    if (!_context){
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _context.persistentStoreCoordinator = self.coordinator;
    }
    return _context;
}

@end
