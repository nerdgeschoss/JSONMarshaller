# JSONMarshaller

JSONMarshaller is a simple drop-in class for marshalling dictionaries from and to NSManagedObjects. Also you can observe managed objects for changes serialize them automatically.

## Usage

Instantiate a marshaller with your entity:

```objective-c
NSManagedObjectContext* context = //pass your context here
NSEntityDescription* productEntity = [NSEntityDescription entityForName: @"Product" inManagedObjectContext: context];
NGBMarshaller* marshaller = [[NGBMarshaller alloc] initWithEntity: productEntity context: context];
NSDictionary* fields = @{@"title": @"Test Product", @"price": @(17.90)};
NSManagedObject* product = [marshaller createObjectWithID:@"1" fields: fields];
```

All entities must be annotated using the managed object model's userInfo (the data model in JSONMarshallerTests is an example).

NGBObservingMarshaller is a subclass of NGBMarshaller that also notifies a delegate if the context is manipulated from outside. You can use this to automatically trigger network requests when the user changes the property of an object. The context doesn't has to be saved for that.

The general flow in your application might be: 
```
[new data from network] -> [json marshaller] -> [context]
[object was changed] -> [json marshaller] -> [delegate] -> [do a network request]
```

## Requirements

JSONMarshaller works only on iOS7 and up.

## Adding JSONMarshaller to your project

### CocoaPods

[CocoaPods](http://cocoapods.org) is the recommended way to add JSONMarshaller to your project.

1. Add a pod entry for JSONMarshaller to your Podfile `pod 'JSONMarshaller', '~> 0.2.0'`
2. Install the pod(s) by running `pod install`.

### Source files

Alternatively you can directly add the source files to your project.

1. Download the [latest code version](https://github.com/nerdgeschoss/JSONMarshaller/archive/master.zip) or add the repository as a git submodule to your git-tracked project. 
2. Open your project in Xcode, then drag and drop all classes in the Lib folder onto your project (use the "Product Navigator view"). Make sure to select Copy items when asked if you extracted the code archive outside of your project. 


## License

This code is distributed under the terms and conditions of the [MIT license](LICENSE). 

## Contributing

Have a new idea or found a bug? Please support this project by contributing pull requests.

First open an issue and state that you're working on something so there is no doubled work. Then submit your pull request.

## Ideas for contributions

- Currently there are some weak parts regarding serialization of relations.
- There's quite a lot of documentation missing.
- Porting to swift?
- Increase the unit test coverage.

## Coding guidelines

* All public methods need to be documented with appledoc syntax.
* If you provide additional functionality, add a unit test.
* If you fix a bug, please add a unit test so the bug will not happen again.