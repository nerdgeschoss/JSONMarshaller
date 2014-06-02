#import "NGBObservingMarshaller.h"

@interface NGBObservingMarshaller()

@property (nonatomic, getter = isMarshalling) BOOL marshalling;

@end

@implementation NGBObservingMarshaller

- (instancetype)initWithEntity:(NSEntityDescription *)entity context:(NSManagedObjectContext *)context
{
    self = [super initWithEntity:entity context:context];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didObserveChanges:) name:NSManagedObjectContextObjectsDidChangeNotification object:context];
    }
    return self;
}

- (void)didObserveChanges:(NSNotification*)notification
{
    if (self.isMarshalling) {
        return;
    }
    
    NSArray* insertedObjectCandidates = notification.userInfo[NSInsertedObjectsKey];
    NSArray* insertedObjects = [self filteredObjectsFromArray:insertedObjectCandidates];
    if (insertedObjects.count) {
        [self.delegate marshaller:self didObserveInsertingObjects:insertedObjects];
    }
    
    NSArray* updatedObjectCandidates = notification.userInfo[NSUpdatedObjectsKey];
    NSArray* updatedObjects = [self filteredObjectsFromArray:updatedObjectCandidates];
    if (updatedObjects.count) {
        [self.delegate marshaller:self didObserveUpdatingObjects:updatedObjects];
    }
    
    
}

- (NSArray*)filteredObjectsFromArray:(NSArray*)array
{
    NSMutableArray* objects = [NSMutableArray array];
    for (NSManagedObject* object in array) {
        if ([object.entity isKindOfEntity:self.entity]) {
            [objects addObject:object];
        }
    }
    return objects;
}

- (void)beginUntrackedChanges
{
    [self.managedObjectContext processPendingChanges];
    self.marshalling = YES;
}

- (void)endUntrackedChanges
{
    [self.managedObjectContext processPendingChanges];
    self.marshalling = NO;
}

#pragma mark - Overwrites

- (NSManagedObject *)createObjectWithID:(NSString *)identifier fields:(NSDictionary *)fields
{
    [self beginUntrackedChanges];
    NSManagedObject* object = [super createObjectWithID:identifier fields:fields];
    [self endUntrackedChanges];
    return object;
}

@end
