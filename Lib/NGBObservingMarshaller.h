#import "NGBMarshaller.h"

@class NGBObservingMarshaller;

@protocol NGBObservingMarshallerDelegate <NSObject>

- (void)marshaller:(NGBObservingMarshaller*)marshaller didObserveInsertingObjects:(NSArray*)deletedObjects;
- (void)marshaller:(NGBObservingMarshaller*)marshaller didObserveUpdatingObjects:(NSArray*)deletedObjects;
- (void)marshaller:(NGBObservingMarshaller*)marshaller didObserveDeletingObjects:(NSArray*)deletedObjects;

@end

@interface NGBObservingMarshaller : NGBMarshaller

@property (nonatomic, weak) id<NGBObservingMarshallerDelegate> delegate;

@end
