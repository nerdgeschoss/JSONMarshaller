#import "NGBObservingMarshaller.h"

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
    NSArray* insertedObjectCandidates = notification.userInfo[NSInsertedObjectsKey];
    NSMutableArray* insertedObjects = [NSMutableArray array];
    for (NSManagedObject* object in insertedObjectCandidates) {
        if ([object.entity isKindOfEntity:self.entity]) {
            [insertedObjects addObject:object];
        }
    }
    [self.delegate marshaller:self didObserveInsertingObjects:insertedObjects];
}

@end
