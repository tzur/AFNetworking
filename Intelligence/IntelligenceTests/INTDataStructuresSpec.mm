// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDataStructures.h"

#import "INTEventMetadata.h"

@interface INTFakeEvent : NSObject
@end

@implementation INTFakeEvent
@end

SpecBegin(INTDataStructures)

__block INTEventMetadata *metadata;
__block INTFakeEvent *event;
__block INTAppContext *context;

beforeEach(^{
  metadata = [[INTEventMetadata alloc] initWithTotalRunTime:1 foregroundRunTime:1
                                            deviceTimestamp:[NSDate date] eventID:[NSUUID UUID]];
  event = [[INTFakeEvent alloc] init];
  context = @{
    @"foo": @"bar",
    @"baz": @1
  };
});

it(@"should perform correct transformation with identity generator", ^{
  auto noopContextGenerator = INTIdentityAppContextGenerator();

  expect(noopContextGenerator(context, metadata, event)).to.equal(context);
});

it(@"should compose context generators correctly", ^{
  NSMutableArray *contextParameters = [NSMutableArray array];
  NSMutableArray *callOrder = [NSMutableArray array];

  auto innerContextResult = @{
    @"que": @"baz",
    @"thud": @2
  };

  auto innerGenerator = ^INTAppContext *(INTAppContext *context, INTEventMetadata *, id) {
    [contextParameters addObject:context];
    [callOrder addObject:@1];
    return innerContextResult;
  };

  auto outerGenerator = ^INTAppContext *(INTAppContext *context, INTEventMetadata *, id) {
    [contextParameters addObject:context];
    [callOrder addObject:@2];
    return @{};
  };

  auto composedContextGenerator =
      INTComposeAppContextGenerators(@[innerGenerator, outerGenerator]);

  composedContextGenerator(context, metadata, event);

  expect(contextParameters).to.equal(@[context, innerContextResult]);
  expect(callOrder).to.equal(@[@1, @2]);
});

it(@"should perform identity transformation when an empty array is given", ^{
  auto contextGenerator = INTComposeAppContextGenerators(@[]);

  expect(contextGenerator(context, metadata, event)).to.equal(context);
});

SpecEnd
