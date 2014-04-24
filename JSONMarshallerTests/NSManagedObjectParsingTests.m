#import "NGBTestCase.h"
#import "NSManagedObject+NGBParsing.h"

@interface NSManagedObjectParsingTests : NGBTestCase

@end

@implementation NSManagedObjectParsingTests

- (void)testDeserializing
{
    NSString* title = @"test";
    NSString* priceString = @"1.17";
    NSString* url = @"http://google.com";
    NSString* subtitle = @"subtitle";
    NSInteger timestamp = 1398110880;
    NSDictionary* date = @{@"$date":@1398110880000}; //add 3 digits for milliseconds
    NSDictionary* fields = @{
                             @"title": title,
                             @"minor_title": subtitle,
                             @"url": url,
                             @"price": priceString,
                             @"created_at": date
                             };
    NSManagedObject* object = [[NSManagedObject alloc] initWithEntity:self.entityDescription insertIntoManagedObjectContext:self.context];
    [object ngb_applyFields:fields];
    NSManagedObject* product = [self getFirstObject];
    XCTAssertEqualObjects([product valueForKey:@"title"], title, @"title should be saved");
    XCTAssertEqualObjects([product valueForKey:@"subtitle"], subtitle, @"subtitle should be saved");
    XCTAssertEqualObjects([product valueForKey:@"url"], [NSURL URLWithString:url], @"url should be saved and transformed");
    XCTAssertEqualObjects([product valueForKey:@"createdAt"], [NSDate dateWithTimeIntervalSince1970:timestamp], @"date should be saved and transformed");
}

- (void)testSerializing
{
    NSString* title = @"test";
    NSString* url = @"http://google.com";
    NSString* subtitle = @"subtitle";
    NSManagedObject* object = [[NSManagedObject alloc] initWithEntity:self.entityDescription insertIntoManagedObjectContext:self.context];
    [object setValue:title forKey:@"title"];
    [object setValue:subtitle forKey:@"subtitle"];
    [object setValue:[NSURL URLWithString:url] forKey:@"url"];
    NSDictionary* result = [object ngb_fields];
    XCTAssertEqualObjects(result[@"title"], title, @"title should be saved");
    XCTAssertEqualObjects(result[@"minor_title"], subtitle, @"subtitle should be saved");
    XCTAssertEqualObjects(result[@"url"], url, @"url should be saved and transformed");
}

- (void)testUpdateMessage
{
    NSString* title = @"test";
    NSString* priceString = @"1.17";
    NSString* url = @"http://google.com";
    NSString* subtitle = @"subtitle";
    NSDictionary* date = @{@"$date":@(1398110880000)};
    NSDictionary* fields = @{
                             @"title": title,
                             @"minor_title": subtitle,
                             @"url": url,
                             @"price": priceString,
                             @"created_at": date
                             };
    NSManagedObject* object = [[NSManagedObject alloc] initWithEntity:self.entityDescription insertIntoManagedObjectContext:self.context];
    [object ngb_applyFields:fields];
    NSManagedObject* product = [self getFirstObject];
    
    NSString* newTitle = @"new Title";
    [product ngb_applyFields:@{@"title":newTitle}];
    
    XCTAssertEqualObjects([object valueForKey:@"title"], newTitle, @"should have an updated title");
}


@end
