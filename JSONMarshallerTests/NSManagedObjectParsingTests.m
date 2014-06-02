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
    NSString* secretPin = @"0000";
    NSManagedObject* object = [[NSManagedObject alloc] initWithEntity:self.entityDescription insertIntoManagedObjectContext:self.context];
    [object setValue:title forKey:@"title"];
    [object setValue:subtitle forKey:@"subtitle"];
    [object setValue:[NSURL URLWithString:url] forKey:@"url"];
    [object setValue:secretPin forKey:@"secretPin"];
    NSDictionary* result = [object ngb_fields];
    XCTAssertEqualObjects(result[@"title"], title, @"title should be saved");
    XCTAssertEqualObjects(result[@"minor_title"], subtitle, @"subtitle should be saved");
    XCTAssertEqualObjects(result[@"url"], url, @"url should be saved and transformed");
    XCTAssertFalse([[result allValues] containsObject:secretPin], @"objects without remote key should not be serialized");
}

- (void)testCreatingNestedObject
{
    NSString* title = @"test";
    NSString* name = @"Klaus";
    NSDictionary* fields = @{
                             @"title": title,
                             @"customer":
                                 @{
                                     @"name": name
                                  }
                             };
    NSManagedObject* object = [[NSManagedObject alloc] initWithEntity:self.entityDescription insertIntoManagedObjectContext:self.context];
    [object ngb_applyFields:fields];
    NSManagedObject* product = [self getFirstObject];
    NSManagedObject* customer = [product valueForKey:@"customer"];
    XCTAssertEqualObjects([customer valueForKey:@"name"], name, @"nested name should be saved");
}

- (void)testCreatingMultipleNestedObjects
{
    NSString* title = @"test";
    NSString* name = @"Klaus";
    NSDictionary* fields = @{
                             @"name": name,
                             @"products":
                                 @[
                                     @{
                                         @"id":@"first-product",
                                         @"title": title
                                         },
                                     @{
                                         @"id":@"second-product",
                                         @"title": title
                                         }
                                     ]
                             };
    NSManagedObject* object = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
    
    [object ngb_applyFields:fields];
    
    NSManagedObject* product = [[object valueForKey:@"products"] anyObject];
    XCTAssertEqualObjects([product valueForKey:@"title"], title, @"nested title should be saved");
    XCTAssertEqual([[object valueForKey:@"products"] count], 2, @"there should be 2 products");
}

- (void)testSerializingNestedObject
{
    NSString* name = @"Klaus";
    NSManagedObject* product = [self createObject];
    NSManagedObject* customer = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
    NSManagedObject* inventory = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"LocalInventory" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
    [customer setValue:name forKey:@"name"];
    [product setValue:customer forKey:@"customer"];
    [inventory setValue:@(5) forKey:@"count"];
    
    NSDictionary* dictionary = [product ngb_fields];

    XCTAssertEqualObjects([dictionary valueForKeyPath:@"customer.name"], name, @"nested name should be saved");
    XCTAssertNil(dictionary[@"inventory"], @"private relations should not be serialized");
}

- (void)testSerializingMultipleNestedObjects
{
    NSString* name = @"Klaus";
    NSManagedObject* product = [self createObject];
    NSManagedObject* customer = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
    [customer setValue:name forKey:@"name"];
    [product setValue:customer forKey:@"customer"];
    
    NSDictionary* dictionary = [customer ngb_fields];
    
    XCTAssertEqual([[dictionary valueForKeyPath:@"products"] count], 1, @"nested name should be saved");
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
