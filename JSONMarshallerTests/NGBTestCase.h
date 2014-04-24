//
//  NGBTestCase.h
//  JSONMarshaller
//
//  Created by Jens Ravens on 24/04/14.
//  Copyright (c) 2014 nerdgeschoss GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#define MOCKITO_SHORTHAND
#import <OCMockito.h>

#define HC_SHORTHAND
#import <OCHamcrest.h>

@interface NGBTestCase : XCTestCase

@property (nonatomic) NSManagedObjectModel* model;
@property (nonatomic) NSPersistentStoreCoordinator* coordinator;
@property (nonatomic) NSManagedObjectContext* context;
@property (nonatomic) NSEntityDescription* entityDescription;

- (NSManagedObject*)createObject;
- (NSManagedObject*)createWithServerID:(NSString*)serverID;
- (NSManagedObject*)getFirstObject;
- (NSArray*)getAllObjects;

@end
