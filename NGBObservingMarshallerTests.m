#import "NGBTestCase.h"
#import "NGBObservingMarshaller.h"

@interface NGBObservingMarshallerTests : NGBTestCase

@property (nonatomic) NGBObservingMarshaller* marshaller;

@end

@implementation NGBObservingMarshallerTests

- (void)testCallingDelegateOnInsert
{
    self.marshaller.delegate = [self delegateMock];
    
    NSManagedObject* object = [self createWithServerID:@"some-id"];
    
    [self.context processPendingChanges];
    [verify(self.marshaller.delegate) marshaller:self.marshaller didObserveInsertingObjects:onlyContains(object,nil)];
}

- (void)testNotCallingDelegateOnInsertOfWrongEntity
{
    self.marshaller.delegate = [self delegateMock];
    
    NSManagedObject* object = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
    
    [self.context processPendingChanges];
    assertThat(object, notNilValue());
    [verifyCount(self.marshaller.delegate, never()) marshaller:self.marshaller didObserveInsertingObjects:notNilValue()];
}

- (void)testNotCallingDelegateOnInsertOfMarshalledEntity
{
    self.marshaller.delegate = [self delegateMock];
    
    NSManagedObject* object = [self.marshaller createObjectWithID:@"some-id" fields:@{}];
    
    [self.context processPendingChanges];
    assertThat(object, notNilValue());
    [verifyCount(self.marshaller.delegate, never()) marshaller:self.marshaller didObserveInsertingObjects:notNilValue()];
}

- (void)testNotCallingDelegateOnInsertOfMarshalledEntityWhileCreatingEntity
{
    self.marshaller.delegate = [self delegateMock];
    
    NSManagedObject* object3 = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
    NSManagedObject* object = [self.marshaller createObjectWithID:@"some-id" fields:@{}];
    NSManagedObject* object2 = [self createWithServerID:@"some-id"];
    
    [self.context processPendingChanges];
    assertThat(object, notNilValue());
    assertThat(object3, notNilValue());
    [verify(self.marshaller.delegate) marshaller:self.marshaller didObserveInsertingObjects:onlyContains(object2,nil)];
}

#pragma mark - Convenience

- (NGBObservingMarshaller*)marshaller
{
    if (!_marshaller) {
        _marshaller = [[NGBObservingMarshaller alloc] initWithEntity:self.entityDescription context:self.context];
    }
    return _marshaller;
}

- (id<NGBObservingMarshallerDelegate>)delegateMock
{
    return mockObjectAndProtocol([NSObject class], @protocol(NGBObservingMarshallerDelegate));
}

@end
