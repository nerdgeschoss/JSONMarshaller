//
//  NGBTestCase.m
//  JSONMarshaller
//
//  Created by Jens Ravens on 24/04/14.
//  Copyright (c) 2014 nerdgeschoss GmbH. All rights reserved.
//

#import "NGBTestCase.h"

@implementation NGBTestCase

- (void)testHealth
{
    XCTAssertNotNil(self.coordinator, @"coordinator should be initialized");
    XCTAssertNotNil(self.context, @"there should be a context");
    XCTAssertNotNil(self.entityDescription, @"there should be an entity in the specified context");
    XCTAssert([self getAllObjects].count == 0, @"there shouldnt be any objects before testing");
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
