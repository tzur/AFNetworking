// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "LTEventBus.h"

#import "LTEventTarget.h"

SpecBegin(LTEventBus)

static const Class kSomeClass = [NSNumber class];
static const Class kSubClass = [NSDecimalNumber class];
static const Class kSuperClass = [NSValue class];
static const Class kOtherClass = [NSString class];

static NSNumber * const kSomeInstance = @1.6;
static NSDecimalNumber * const kSubInstance = [NSDecimalNumber decimalNumberWithString:@"1.6"];
static NSValue * const kSuperInstance = [NSValue valueWithCGPoint:CGPointZero];
static NSString * const kOtherInstance = @"abc";

__block LTEventBus *eventBus;

beforeEach(^{
  eventBus = [[LTEventBus alloc] init];
});

context(@"registering", ^{
  __block LTEventTarget *target;

  beforeEach(^{
    target = [[LTEventTarget alloc] init];
  });

  it(@"should observe event of same class", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should observe event of subclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus post:kSubInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should not observe event of superclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus post:kSuperInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should not observe event of different class", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus post:kOtherInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should receive same object", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).to.equal(kSomeInstance);
    expect(target.object == kSomeInstance).to.beTruthy();
  });
});

context(@"unregistering", ^{
  __block LTEventTarget *target;

  beforeEach(^{
    target = [[LTEventTarget alloc] init];
  });

  it(@"should not observe after unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus removeObserver:target forClass:kSomeClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should not observe after unregistering superclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus removeObserver:target forClass:kSuperClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should still observe after unregistering subclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus removeObserver:target forClass:kSubClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should still observe after unregistering other class", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus removeObserver:target forClass:kOtherClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });
});

context(@"multiple registrations", ^{
  __block LTEventTarget *target;

  beforeEach(^{
    target = [[LTEventTarget alloc] init];
  });

  it(@"should call twice when registering twice", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(2);
    expect(target.object).toNot.beNil();
  });

  it(@"should call twice when registering for class and superclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSuperClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(2);
    expect(target.object).toNot.beNil();
  });

  it(@"should call once when registering for class and subclass", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should not call after registering twice and unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus removeObserver:target forClass:kSomeClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });

  it(@"should call once after registering super and unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSuperClass];
    [eventBus removeObserver:target forClass:kSomeClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(1);
    expect(target.object).toNot.beNil();
  });

  it(@"should not call after registering sub and unregistering", ^{
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];
    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSubClass];
    [eventBus removeObserver:target forClass:kSomeClass];
    [eventBus post:kSomeInstance];
    expect(target.counter).to.equal(0);
    expect(target.object).to.beNil();
  });
});

context(@"dealloc", ^{
  it(@"should handle dealloc'ed targets", ^{
    LTEventTarget *target = [[LTEventTarget alloc] init];

    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];

    target = nil;

    expect(^{
      [eventBus post:kSomeInstance];
    }).toNot.raiseAny();
  });

  it(@"should not retain targets", ^{
    LTEventTarget *target = [[LTEventTarget alloc] init];
    __weak LTEventTarget *weakTarget = target;

    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];

    target = nil;

    expect(weakTarget).to.beNil();
  });

  it(@"should not retain targets after posting", ^{
    LTEventTarget *target = [[LTEventTarget alloc] init];
    __weak LTEventTarget *weakTarget = target;

    [eventBus addObserver:target selector:@selector(handleEvent:) forClass:kSomeClass];

    @autoreleasepool {
      [eventBus post:kSomeInstance];
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
      [eventBus addObserver:target selector:@selector(badSelector) forClass:kSomeClass];
    }).to.raiseAny();

    expect(^{
      [eventBus addObserver:target selector:@selector(badSelector2:) forClass:kSomeClass];
    }).to.raiseAny();

    expect(^{
      [eventBus addObserver:target selector:@selector(badSelector3:withValue:)
                   forClass:kSomeClass];
    }).to.raiseAny();

    expect(^{
      [eventBus addObserver:target selector:@selector(badSelector4:withAnother:)
                   forClass:kSomeClass];
    }).to.raiseAny();
  });

  it(@"should not accept nil objects", ^{
    expect(^{
      id object = nil;
      [eventBus post:object];
    }).to.raiseAny();
  });

  it(@"should not accept nil classes", ^{
    expect(^{
      Class someClass = nil;
      [eventBus addObserver:target selector:@selector(handleEvent:) forClass:someClass];
    }).to.raiseAny();
  });
});

SpecEnd
