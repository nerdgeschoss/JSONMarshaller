//
//  NSManagedObject+NGBParsing.h
//  DDPClient
//
//  Created by Jens Ravens on 21/04/14.
//  Copyright (c) 2014 Jens Ravens. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (NGBParsing)

- (void)ngb_applyFields:(NSDictionary*)fields;
- (NSDictionary*)ngb_fields;

- (void)ngb_performWriting:(void(^)(NSManagedObjectContext* context, id object))writingBlock;

@end
