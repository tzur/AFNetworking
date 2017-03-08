// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "LTEventBus.h"

#import "LTEventTarget.h"

@protocol LTEventBusBaseProtocol <NSObject>
@end

@protocol LTEventBusSubBaseProtocol <LTEventBusBaseProtocol>
@end

@protocol LTEventBusSubSubBaseProtocol <LTEventBusSubBaseProtocol>
@end

@protocol LTEventBusOtherProtocol <NSObject>
@end

@interface LTEventBusBaseProtocol : NSObject <LTEventBusBaseProtocol>
@end

@interface LTEventBusSubBaseProtocol : NSObject <LTEventBusSubBaseProtocol>
@end

@interface LTEventBusSubSubBaseProtocol : NSObject <LTEventBusSubSubBaseProtocol>
@end

@interface LTEventBusOtherProtocol : NSObject <LTEventBusOtherProtocol>
@end

@implementation LTEventBusBaseProtocol
@end

@implementation LTEventBusSubBaseProtocol
@end

@implementation LTEventBusSubSubBaseProtocol
@end

@implementation LTEventBusOtherProtocol
@end

@interface LTDynamicEventHandler : NSObject
@property (strong, nonatomic, nullable) void (^handleEventBlock)(id);
@end

@implementation LTDynamicEventHandler
- (void)handleEvent:(id)event {
  if (self.handleEventBlock) {
    self.handleEventBlock(event);
  }
}
@end

SpecBegin(LTEventBus)

static const Class kBaseClass = [NSValue class];
static const Class kSubBaseClass = [NSNumber class];
static const Class kSubSubBaseClass = [NSDecimalNumber class];
static const Class kOtherClass = [NSString class];

static NSValue * const kBaseInstance = [NSValue valueWithCGPoint:CGPointZero];
static NSNumber * const kSubBaseInstance = @1.6;
static NSDecimalNumber * const kSubSubBaseInstance =
    [NSDecimalNumber decimalNumberWithString:@"1.6"];
static NSString * const kOtherInstance = @"abc";

static Protocol * const kBaseProtocol = @protocol(LTEventBusBaseProtocol);
static Protocol * const kSubBaseProtocol = @protocol(LTEventBusSubBaseProtocol);
static Protocol * const kSubSubBaseProtocol = @protocol(LTEventBusSubSubBaseProtocol);
static Protocol * const kOtherProtocol = @protocol(LTEventBusOtherProtocol);

static LTEventBusBaseProtocol * const kBaseProtocolInstance = [[LTEventBusBaseProtocol alloc] init];
static LTEventBusSubBaseProtocol * const kSubBaseProtocolInstance =
    [[LTEventBusSubBaseProtocol alloc] init];
static LTEventBusSubSubBaseProtocol * const kSubSubBaseProtocolInstance =
    [[LTEventBusSubSubBaseProtocol alloc] init];
static LTEventBusOtherProtocol * const kOtherProtocolInstance =
    [[LTEventBusOtherProtocol alloc] init];

__block LTEventBus *eventBus;

beforeEach(^{
  eventBus = [[LTEventBus alloc] init];
});

context(@"class registering", ^{
  __block LTEventTarget *target;

  beforeEach(^{
    target = [[LTEventTarget alloc] init];
  });

  it(@"should observe event of same class", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should observe event of subclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus post:kSubSubBaseInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should not observe event of superclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus post:kBaseInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should not observe event of different class", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus post:kOtherInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should receive same object", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).to.equal(kSubBaseInstance);
    expect(target.object).to.beIdenticalTo(kSubBaseInstance);
  });
});

context(@"protocol registering", ^{
  __block LTEventTarget *target;

  beforeEach(^{
    target = [[LTEventTarget alloc] init];
  });

  it(@"should observe event of same protocol", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should observe event of subprotocol", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus post:kSubSubBaseProtocolInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should not observe event of superprotocol", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus post:kBaseProtocolInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should not observe event of different protocol", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus post:kOtherProtocolInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should receive same object", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).to.equal(kSubBaseProtocolInstance);
    expect(target.object).to.beIdenticalTo(kSubBaseProtocolInstance);
  });
});

context(@"class unregistering", ^{
  __block LTEventTarget *target;

  beforeEach(^{
    target = [[LTEventTarget alloc] init];
  });

  it(@"should not observe class after unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus removeObserver:target forClass:kSubBaseClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should not observe after unregistering superclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus removeObserver:target forClass:kBaseClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should still observe after unregistering subclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus removeObserver:target forClass:kSubSubBaseClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should still observe after unregistering other class", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus removeObserver:target forClass:kOtherClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });
});

context(@"protocol unregistering", ^{
  __block LTEventTarget *target;

  beforeEach(^{
    target = [[LTEventTarget alloc] init];
  });
  it(@"should not observe protocol after unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus removeObserver:target forProtocol:kSubBaseProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should not observe after unregistering superprotocol", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus removeObserver:target forProtocol:kBaseProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should still observe after unregistering subprotocol", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus removeObserver:target forProtocol:kSubSubBaseProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should still observe after unregistering other protocol", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus removeObserver:target forProtocol:kOtherProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });
});

context(@"class multiple registrations", ^{
  __block LTEventTarget *target;

  beforeEach(^{
    target = [[LTEventTarget alloc] init];
  });

  it(@"should call twice when registering twice to a class", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(2);
    expect(target.object).toNot.beNil();
  });

  it(@"should call twice when registering for class and superclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kBaseClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(2);
    expect(target.object).toNot.beNil();
  });

  it(@"should call once when registering for class and subclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubSubBaseClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should not call after registering twice for a class and unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus removeObserver:target forClass:kSubBaseClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should call once after registering superclass and unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kBaseClass];
    [eventBus removeObserver:target forClass:kSubBaseClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should not call after registering subclass and unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubSubBaseClass];
    [eventBus removeObserver:target forClass:kSubBaseClass];
    [eventBus post:kSubBaseInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });
});

context(@"protocol multiple registrations", ^{
  __block LTEventTarget *target;

  beforeEach(^{
    target = [[LTEventTarget alloc] init];
  });

  it(@"should call twice when registering twice to a protocol", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(2);
    expect(target.object).toNot.beNil();
  });

  it(@"should call twice when registering for protocol and superprotocol", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kBaseProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(2);
    expect(target.object).toNot.beNil();
  });

  it(@"should call once when registering for protocol and subprotocol", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubSubBaseProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should not call after registering twice for a protocol and unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus removeObserver:target forProtocol:kSubBaseProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should call once after registering superprotocol and unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kBaseProtocol];
    [eventBus removeObserver:target forProtocol:kSubBaseProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should not call after registering subprotocol and unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubSubBaseProtocol];
    [eventBus removeObserver:target forProtocol:kSubBaseProtocol];
    [eventBus post:kSubBaseProtocolInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });
});

context(@"dealloc", ^{
  it(@"should handle dealloc'ed targets", ^{
    LTEventTarget *target = [[LTEventTarget alloc] init];

    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];
    target = nil;

    expect(^{
      [eventBus post:kSubBaseInstance];
      [eventBus post:kSubBaseProtocolInstance];
    }).toNot.raiseAny();
  });

  it(@"should not retain targets", ^{
    LTEventTarget *target = [[LTEventTarget alloc] init];
    __weak LTEventTarget *weakTarget = target;

    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];

    target = nil;

    expect(weakTarget).to.beNil();
  });

  it(@"should not retain targets after posting", ^{
    LTEventTarget *target = [[LTEventTarget alloc] init];
    __weak LTEventTarget *weakTarget = target;

    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubBaseClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forProtocol:kSubBaseProtocol];

    @autoreleasepool {
      [eventBus post:kSubBaseInstance];
      [eventBus post:kSubBaseProtocolInstance];
    }

    target = nil;

    expect(weakTarget).to.beNil();
  });
});

context(@"api verification", ^{
  __block LTEventTarget *target;

  beforeEach(^{
    target = [[LTEventTarget alloc] init];
  });

  it(@"should not accept a wrong selector", ^{
    expect(^{
      [eventBus addObserver:target selector:@selector(badSelector) forClass:kSubBaseClass];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [eventBus addObserver:target selector:@selector(badSelector2:) forClass:kSubBaseClass];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [eventBus addObserver:target selector:@selector(badSelector3:withValue:)
                   forClass:kSubBaseClass];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [eventBus addObserver:target selector:@selector(badSelector4:withAnother:)
                   forClass:kSubBaseClass];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [eventBus addObserver:target selector:@selector(badSelector) forProtocol:kSubBaseProtocol];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [eventBus addObserver:target selector:@selector(badSelector2:) forProtocol:kSubBaseProtocol];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [eventBus addObserver:target selector:@selector(badSelector3:withValue:)
                forProtocol:kSubBaseProtocol];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [eventBus addObserver:target selector:@selector(badSelector4:withAnother:)
                forProtocol:kSubBaseProtocol];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"nested events", ^{
  __block LTDynamicEventHandler *dynamicHandler;
  __block LTDynamicEventHandler *otherDynamicHandler;

  beforeEach(^{
    dynamicHandler = [[LTDynamicEventHandler alloc] init];
    otherDynamicHandler = [[LTDynamicEventHandler alloc] init];
  });

  it(@"should complete posting nested events before the original event", ^{
    static NSString * const kString = @"foo";
    static NSNumber * const kNumber = @12;
    
    __block NSMutableArray *receivedObjects = [NSMutableArray array];

    dynamicHandler.handleEventBlock = ^(id value) {
      [eventBus post:kString];
      [receivedObjects addObject:value];
    };
    
    otherDynamicHandler.handleEventBlock = ^(id value) {
      [receivedObjects addObject:value];
    };

    [eventBus addObserver:dynamicHandler selector:@selector(handleEvent:)
                 forClass:[NSNumber class]];
    [eventBus addObserver:otherDynamicHandler selector:@selector(handleEvent:)
                 forClass:[NSString class]];
    [eventBus post:kNumber];

    expect(receivedObjects).to.equal(@[kString, kNumber]);
  });
});

context(@"synchronized posting", ^{
  __block LTDynamicEventHandler *dynamicHandler;

  beforeEach(^{
    dynamicHandler = [[LTDynamicEventHandler alloc] init];
  });

  it(@"should notify observers on the same queue an object was posted", ^{
    dispatch_queue_t postQueue = dispatch_queue_create("com.lightricks.LTKit.EventBusTests",
                                                       DISPATCH_QUEUE_SERIAL);
    __block NSString *postQueueName;
    dynamicHandler.handleEventBlock = ^(id) {
      postQueueName =
          [NSString stringWithUTF8String:dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];
    };

    [eventBus addObserver:dynamicHandler selector:@selector(handleEvent:)
                 forClass:[NSString class]];
    dispatch_sync(postQueue, ^{
      [eventBus post:@""];
    });
    NSString *expectedQueueName =
        [NSString stringWithUTF8String:dispatch_queue_get_label(postQueue)];

    expect(postQueueName).to.equal(expectedQueueName);
  });

  it(@"should notify observers on the same thread an object was posted", ^{
    __block NSThread *postThread;
    dynamicHandler.handleEventBlock = ^(id) {
      postThread = [NSThread currentThread];
    };

    [eventBus addObserver:dynamicHandler selector:@selector(handleEvent:)
                 forClass:[NSString class]];
    [eventBus post:@""];
    NSThread *currentThread = [NSThread currentThread];

    expect(postThread).to.equal(currentThread);
  });
});

SpecEnd
