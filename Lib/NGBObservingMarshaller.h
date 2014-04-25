#import "NGBMarshaller.h"

@class NGBObservingMarshaller;

@protocol NGBObservingMarshallerDelegate <NSObject>

- (void)marshaller:(NGBObservingMarshaller*)marshaller didObserveInsertingObjects:(NSArray*)insertedObjects;
- (void)marshaller:(NGBObservingMarshaller*)marshaller didObserveUpdatingObjects:(NSArray*)updatedObjects;
- (void)marshaller:(NGBObservingMarshaller*)marshaller didObserveDeletingObjects:(NSArray*)deletedObjects;

@end

@interface NGBObservingMarshaller : NGBMarshaller

@property (nonatomic, weak) id<NGBObservingMarshallerDelegate> delegate;

- (void)beginUntrackedChanges;
- (void)endUntrackedChanges;

@end
