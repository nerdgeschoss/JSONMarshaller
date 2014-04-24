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
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:self.ngb_entityName];
    request.fetchLimit = 1;
    request.predicate = [NSPredicate predicateWithFormat:@"%K == %@", [self.class ngb_serverIDKeyForEntity:self.entity], serverID];
    return [[self.managedObjectContext executeFetchRequest:request error:nil] firstObject];
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
    NSString* serverKey = entity.userInfo[@"serverKey"];
    if (!serverKey) {
        serverKey = @"serverID";
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
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    NSEntityDescription* entityDescription = self.entity;
    
    NSDictionary* properties = entityDescription.attributesByName;
    for (NSString* attributeKey in properties){
        NSAttributeDescription* attribute = properties[attributeKey];
        NSString* sourceKey = [self.class ngb_sourceKeyForAttribute:attribute];
        id value = [self ngb_valueForAttribute:attribute];
        if (value) {
            dictionary[sourceKey] = value;
        }
    }
    
    NSDictionary* relations = entityDescription.relationshipsByName;
    for (NSString* relationKey in relations) {
        NSRelationshipDescription* relationship = relations[relationKey];
        NSString* sourceKey = [self.class ngb_sourceKeyForRelationship:relationship];
        id value = [self valueForKey:relationship.name];
        if (value) {
            if (relationship.isToMany) {
                NSMutableArray* array = [NSMutableArray array];
                for (NSManagedObject* object in value) {
                    NSDictionary* fields = [object ngb_fields];
                    if (fields) {
                        [array addObject:fields];
                    }
                }
                dictionary[sourceKey] = array;
            } else {
                if ([value isKindOfClass:[NSManagedObject class]]) {
                    dictionary[sourceKey] = [value ngb_fields];
                }
            }
        }
    }
    return dictionary;
}

+ (NSString*)ngb_sourceKeyForAttribute:(NSAttributeDescription*)attribute
{
    return [self ngb_sourceKeyForPropertyWithName:attribute.name ofEntity:attribute.entity];
}

+ (NSString*)ngb_sourceKeyForRelationship:(NSRelationshipDescription*)relationship
{
    return [self ngb_sourceKeyForPropertyWithName:relationship.name ofEntity:relationship.entity];
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
        for (NSDictionary* elementDictionary in fields) {
            NSString* serverID = elementDictionary[[self.class ngb_serverIDKeyForEntity:self.entity]];
            if (serverID) {
                
                NSManagedObject* childObject = [self ngb_objectForServerID:serverID];
                [childObject ngb_applyFields:elementDictionary];
            } else {
                NSAssert(false, @"Missing server ID in response.");
                return;
            }
        }
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

@end
