//
//  NGBJSONMarshaller.m
//  JSONMarshaller
//
//  Created by Jens Ravens on 24/04/14.
//  Copyright (c) 2014 nerdgeschoss GmbH. All rights reserved.
//

#import "NGBMarshaller.h"
#import "NSManagedObject+NGBParsing.h"

@interface NGBMarshaller()

@property (nonatomic) NSEntityDescription* entity;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;

@end

@interface NSManagedObject (NGBInternal)

+ (NSString*)ngb_serverIDKeyForEntity:(NSEntityDescription*)entity;

@end

@implementation NGBMarshaller

- (instancetype)initWithEntity:(NSEntityDescription *)entity context:(NSManagedObjectContext *)context
{
    self = [self init];
    if (self) {
        _entity = entity;
        _managedObjectContext = context;
    }
    return self;
}

- (NSManagedObject*)createObjectWithID:(NSString *)identifier fields:(NSDictionary *)fields
{
    NSManagedObject* object = [[NSManagedObject alloc] initWithEntity:self.entity insertIntoManagedObjectContext:self.managedObjectContext];
    NSString* serverKey = [NSManagedObject ngb_serverIDKeyForEntity:self.entity];
    [object setValue:identifier forKey:serverKey];
    [self updateObject:object fields:fields];
    return object;
}

- (NSManagedObject *)updateObject:(NSManagedObject *)object fields:(NSDictionary *)fields
{
    [object ngb_applyFields:fields];
    return object;
}

- (NSManagedObject *)updateObjectWithID:(NSString *)identifier fields:(NSDictionary *)fields
{
    NSManagedObject* object = [self objectForServerID:identifier];
    return [self updateObject:object fields:fields];
}

- (NSManagedObject *)upsertObjectWithID:(NSString *)identifier fields:(NSDictionary *)fields
{
    NSManagedObject* object = [self objectForServerID:identifier];
    if (object) {
        [self updateObject:object fields:fields];
    } else {
        object = [self createObjectWithID:identifier fields:fields];
    }
    return object;
}

- (BOOL)deleteObjectWithID:(NSString *)identifier
{
    NSManagedObject* object = [self objectForServerID:identifier];
    if (object) {
        [self.managedObjectContext deleteObject:object];
        return YES;
    }
    return NO;
}

#pragma mark - Helper Methods

- (NSManagedObject*)objectForServerID:(NSString*)serverID
{
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:self.entity.name];
    request.fetchLimit = 1;
    request.predicate = [NSPredicate predicateWithFormat:@"%K == %@", [NSManagedObject ngb_serverIDKeyForEntity:self.entity], serverID];
    return [[self.managedObjectContext executeFetchRequest:request error:nil] firstObject];
}

@end
