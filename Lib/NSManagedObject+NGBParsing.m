//
//  NSManagedObject+NGBParsing.m
//  RestCoreDataParser
//
//  Created by Jens Ravens on 21/04/14.
//  Copyright (c) 2014 nerdgeschoss GmbH. All rights reserved.
//

#import "NSManagedObject+NGBParsing.h"

@interface NSManagedObject (NGBParsing_internal)

@property (nonatomic, readonly) NSString* ngb_entityName;

@end

@implementation NSManagedObject (NGBParsing)

- (NSString*)ngb_entityName
{
    return self.entity.name;
}

- (NSManagedObject*)ngb_objectForServerID:(NSString*)serverID
{
    return [self ngb_objectForServerID:serverID entity:self.entity createIfNotPresent:NO];
}

- (NSManagedObject*)ngb_objectForServerID:(NSString*)serverID entity:(NSEntityDescription*)entity createIfNotPresent:(BOOL)createIfNotPresent
{
    NSString* serverKey = [self.class ngb_serverIDKeyForEntity:entity];
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:entity.name];
    request.fetchLimit = 1;
    request.predicate = [NSPredicate predicateWithFormat:@"%K == %@", serverKey, serverID];
    NSManagedObject* object = [[self.managedObjectContext executeFetchRequest:request error:nil] firstObject];
    if (!object && createIfNotPresent) {
        object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
        [object setValue:serverID forKey:serverKey];
    }
    return object;
}

- (void)ngb_applyValue:(id)value forAttribute:(NSAttributeDescription*)attribute
{
    switch (attribute.attributeType) {
        case NSFloatAttributeType:
            [self setValue:@([value floatValue]) forKey:attribute.name];
            break;
        case NSDoubleAttributeType:
            [self setValue:@([value doubleValue]) forKey:attribute.name];
            break;
        case NSDecimalAttributeType:
            [self setValue:@([value doubleValue]) forKey:attribute.name];
            break;
        case NSStringAttributeType:
            [self setValue:[value description] forKey:attribute.name];
            break;
        case NSDateAttributeType:{
            NSDate* date = [self.class ngb_objectFromValue:value ofCustomType:@"$date"];
            [self setValue:date forKey:attribute.name];
            break;
        }
            
        case NSTransformableAttributeType:{
            NSString* type = [self.class ngb_typeForAttribute:attribute];
            id object = [self.class ngb_objectFromValue:value ofCustomType:type];
            [self setValue:object forKey:attribute.name];
        }
            break;
        default:
            NSAssert(false, @"Unsupported Attribute Type");
            break;
    }
}

- (id)ngb_valueForAttribute:(NSAttributeDescription*)attribute
{
    id value = [self valueForKey:attribute.name];
    switch (attribute.attributeType) {
        case NSFloatAttributeType:
        case NSDoubleAttributeType:
        case NSDecimalAttributeType:
            return [value stringValue];
            break;
        case NSStringAttributeType:
            return value;
            break;
        case NSDateAttributeType:{
            return [self.class ngb_valueFromObject:value ofCustomType:@"$date"];
            break;
        }
            
        case NSTransformableAttributeType:{
            NSString* type = [self.class ngb_typeForAttribute:attribute];
            return [self.class ngb_valueFromObject:value ofCustomType:type];
        }
            break;
        default:
            NSAssert(false, @"Unsupported Attribute Type");
            break;
    }
    return nil;
}

+ (NSString*)ngb_serverIDKeyForEntity:(NSEntityDescription*)entity
{
    NSParameterAssert(entity);
    NSString* serverKey = entity.userInfo[@"PrimaryKey"];
    if (!serverKey) {
        serverKey = @"serverID";
    }
    return serverKey;
}

+ (NSString*)ngb_remoteIDKeyForEntity:(NSEntityDescription*)entity
{
    NSParameterAssert(entity);
    NSString* primaryKey = entity.userInfo[@"PrimaryKey"];
    NSRelationshipDescription* relation = entity.relationshipsByName[primaryKey];
    NSString* serverKey = relation.userInfo[@"RemoteKey"];
    if (!serverKey) {
        serverKey = @"id";
    }
    return serverKey;
}

+ (id)ngb_typeForAttribute:(NSAttributeDescription*)attribute
{
    return attribute.userInfo[@"type"];
}

+ (id)ngb_objectFromValue:(id)value ofCustomType:(NSString*)type
{
    if ([type isEqualToString:@"url"]){
        if ([value isKindOfClass:[NSString class]]) {
            return [NSURL URLWithString:value];
        }
    } else if ([type isEqualToString:@"$date"]){
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSString* dateValue = ((NSDictionary*)value)[@"$date"];
            if (dateValue) {
                return [NSDate dateWithTimeIntervalSince1970:[dateValue doubleValue] * 0.001];
            }
        }
    } else {
        NSAssert(false, @"Unsupported Type %@", type);
    }
    return nil;
}

+ (id)ngb_valueFromObject:(id)object ofCustomType:(NSString*)type
{
    if ([type isEqualToString:@"url"]){
        if ([object isKindOfClass:[NSURL class]]) {
            return [(NSURL*)object absoluteString];
        }
    } else if ([type isEqualToString:@"$date"]){
        if ([object isKindOfClass:[NSDate class]]) {
            if (!object) {
                return nil;
            }
            NSNumber* milliseconds = @(floor([object timeIntervalSince1970] * 1000));
            return @{@"$date": milliseconds};
        }
    } else {
        NSAssert(false, @"Unsupported Type %@", type);
    }
    return nil;
}

- (void)ngb_applyFields:(NSDictionary*)fields
{
    NSEntityDescription* entityDescription = self.entity;
    NSDictionary* properties = entityDescription.attributesByName;
    for (NSString* attributeKey in properties){
        NSAttributeDescription* attribute = properties[attributeKey];
        NSString* sourceKey = [self.class ngb_sourceKeyForAttribute:attribute];
        NSString* value = fields[sourceKey];
        if (value) { //there is an update. use it.
            [self ngb_applyValue:value forAttribute:attribute];
        }
    }
    
    NSDictionary* relations = entityDescription.relationshipsByName;
    for (NSString* relationKey in relations) {
        NSRelationshipDescription* relationship = relations[relationKey];
        NSString* sourceKey = [self.class ngb_sourceKeyForRelationship:relationship];
        NSDictionary* value = fields[sourceKey];
        if (value) {//there is a related object
            [self ngb_applyFields:value toRelationship:relationship];
        }
    }
}

- (NSDictionary*)ngb_fields
{
    return [self ngb_fieldsAlreadySerializedObjects:nil];
}

- (NSDictionary*)ngb_fieldsAlreadySerializedObjects:(NSMutableArray*)alreadySerializedObjects
{
    if (!alreadySerializedObjects) {
        alreadySerializedObjects = [NSMutableArray array];
    }
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    NSEntityDescription* entityDescription = self.entity;
    
    NSDictionary* properties = entityDescription.attributesByName;
    for (NSString* attributeKey in properties){
        NSAttributeDescription* attribute = properties[attributeKey];
        NSString* sourceKey = [self.class ngb_sourceKeyForAttribute:attribute];
        id value = [self ngb_valueForAttribute:attribute];
        if (sourceKey && value) {
            dictionary[sourceKey] = value;
        }
    }
    
    [alreadySerializedObjects addObject:self];
    
    NSDictionary* relations = entityDescription.relationshipsByName;
    for (NSString* relationKey in relations) {
        NSRelationshipDescription* relationship = relations[relationKey];
        NSString* sourceKey = [self.class ngb_sourceKeyForRelationship:relationship];
        id value = [self valueForKey:relationship.name];
        if (sourceKey && value) {
            if (relationship.isToMany) {
                BOOL alreadyPresent = NO;
                NSMutableArray* array = [NSMutableArray array];
                for (NSManagedObject* object in value) {
                    if ([alreadySerializedObjects containsObject:object]) {
                        alreadyPresent = YES;
                        break;
                    }
                    NSDictionary* fields = [object ngb_fieldsAlreadySerializedObjects:alreadySerializedObjects];
                    if (fields) {
                        [array addObject:fields];
                    }
                }
                if (!alreadyPresent) {
                    dictionary[sourceKey] = array;
                }
                
            } else {
                if ([value isKindOfClass:[NSManagedObject class]] && ![alreadySerializedObjects containsObject:value]) {
                    dictionary[sourceKey] = [value ngb_fieldsAlreadySerializedObjects:alreadySerializedObjects];
                }
            }
        }
    }
    return dictionary;
}

+ (NSString*)ngb_sourceKeyForAttribute:(NSAttributeDescription*)attribute
{
    return attribute.userInfo[@"RemoteKey"];
}

+ (NSString*)ngb_sourceKeyForRelationship:(NSRelationshipDescription*)relationship
{
    return relationship.userInfo[@"RemoteKey"];
}

+ (NSString*)ngb_sourceKeyForPropertyWithName:(NSString*)name ofEntity:(NSEntityDescription*)entity
{
    //check if the source key is overridden
    NSString* sourceKey = [[entity.userInfo allKeysForObject:name] firstObject];
    if (!sourceKey){ //no? then use default
        sourceKey = name;
    }
    return sourceKey;
}

- (void)ngb_applyFields:(id)fields toRelationship:(NSRelationshipDescription*)relationship
{
    if (relationship.isToMany) {
        if (![fields isKindOfClass:[NSArray class]]) {
            NSAssert(false, @"Object in result is of wrong type.");
            return;
        }
        NSMutableSet* relationObjects = [[self valueForKey:relationship.name] mutableCopy];
        for (NSDictionary* elementDictionary in fields) {
            NSString* serverID = elementDictionary[[self.class ngb_remoteIDKeyForEntity:self.entity]];
            if (serverID) {
                
                NSManagedObject* childObject = [self ngb_objectForServerID:serverID entity:relationship.destinationEntity createIfNotPresent:YES];
                if (![relationObjects containsObject:childObject]) {
                    [relationObjects addObject:childObject];
                }
                [childObject ngb_applyFields:elementDictionary];
            } else {
                NSAssert(false, @"Missing server ID in response.");
                return;
            }
        }
        [self setValue:relationObjects forKey:relationship.name];
    } else {
        if (![fields isKindOfClass:[NSDictionary class]]) {
            NSAssert(false, @"Object in result is of wrong type.");
            return;
        }
        NSManagedObject* relationObject = [self valueForKey:relationship.name];
        if (!relationObject) {
            relationObject = [[NSManagedObject alloc] initWithEntity:relationship.destinationEntity insertIntoManagedObjectContext:self.managedObjectContext];
            [self setValue:relationObject forKey:relationship.name];
        }
        [relationObject ngb_applyFields:fields];
    }
}

- (void)ngb_performWriting:(void (^)(NSManagedObjectContext *, id))writingBlock
{
    NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = self.managedObjectContext;
    NSManagedObjectID* objectID = self.objectID;
    [context performBlockAndWait:^{
        NSManagedObject* object = [context objectWithID:objectID];
        writingBlock(context, object);
    }];
}

@end
