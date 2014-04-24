//
//  NGBJSONMarshaller.h
//  JSONMarshaller
//
//  Created by Jens Ravens on 24/04/14.
//  Copyright (c) 2014 nerdgeschoss GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NGBMarshaller : NSObject

@property (nonatomic, readonly) NSEntityDescription* entity;
@property (nonatomic, readonly) NSManagedObjectContext* managedObjectContext;

- (instancetype)initWithEntity:(NSEntityDescription*)entity context:(NSManagedObjectContext*)context;

- (NSManagedObject*)createObjectWithID:(NSString*)identifier fields:(NSDictionary*)fields;
- (NSManagedObject*)upsertObjectWithID:(NSString*)identifier fields:(NSDictionary*)fields;
- (NSManagedObject*)updateObjectWithID:(NSString*)identifier fields:(NSDictionary*)fields;
- (NSManagedObject*)updateObject:(NSManagedObject*)object fields:(NSDictionary*)fields;
- (BOOL)deleteObjectWithID:(NSString*)identifier;

@end
