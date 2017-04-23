// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTEventTransformer.h"

#import "INTDataStructures.h"
#import "INTEventMetadata.h"

SpecBegin(INTEventTransformer)

__block INTEventMetadata *metadata;

beforeEach(^{
  metadata = [[INTEventMetadata alloc] initWithTotalRunTime:1 foregroundRunTime:1
                                            deviceTimestamp:[NSDate date] eventID:[NSUUID UUID]];
});

it(@"should return transformed events from a transformer block", ^{
  auto transformerBlock =
      ^(NSDictionary<NSString *, id> *, INTAppContext *, INTEventMetadata *, id) {
        return intl::TransformerBlockResult(nil, @[@"foo", @"bar"]);
      };

  auto transformer = [[INTEventTransformer alloc] initWithTransformerBlocks:{
    transformerBlock
  }];

  auto expected = @[@"foo", @"bar"];
  expect([transformer processEvent:@"baz" metadata:metadata appContext:@{}]).to.equal(expected);
  expect([transformer processEvent:@"que" metadata:metadata appContext:@{}]).to.equal(expected);
});

it(@"should persist aggregated data across event processes", ^{
  auto transformerBlock =
      ^(NSDictionary<NSString *, id> *aggregatedData, INTAppContext *, INTEventMetadata *, id) {
        NSUInteger counter = [aggregatedData[@"counter"] unsignedIntegerValue];

        return intl::TransformerBlockResult(@{@"counter": @(counter + 1)}, @[@(counter)]);
      };

  auto transformer = [[INTEventTransformer alloc] initWithTransformerBlocks:{
    transformerBlock
  }];

  expect([transformer processEvent:@"foo" metadata:metadata appContext:@{}]).to.equal(@[@0]);
  expect([transformer processEvent:@"bar" metadata:metadata appContext:@{}]).to.equal(@[@1]);
  expect([transformer processEvent:@"bar" metadata:metadata appContext:@{}]).to.equal(@[@2]);
});

it(@"should not persist aggregated data across initializations", ^{
  auto transformerBlock =
      ^(NSDictionary<NSString *, id> *aggregatedData, INTAppContext *, INTEventMetadata *, id) {
        NSUInteger counter = [aggregatedData[@"counter"] unsignedIntegerValue];

        return intl::TransformerBlockResult(@{@"counter": @(counter + 1)}, @[@(counter)]);
      };

  auto transformer = [[INTEventTransformer alloc] initWithTransformerBlocks:{
    transformerBlock
  }];

  expect([transformer processEvent:@"foo" metadata:metadata appContext:@{}]).to.equal(@[@0]);
  expect([transformer processEvent:@"bar" metadata:metadata appContext:@{}]).to.equal(@[@1]);

  transformer = [[INTEventTransformer alloc] initWithTransformerBlocks:{
    transformerBlock
  }];

  expect([transformer processEvent:@"foo" metadata:metadata appContext:@{}]).to.equal(@[@0]);
  expect([transformer processEvent:@"bar" metadata:metadata appContext:@{}]).to.equal(@[@1]);
});

it(@"should pass metadata to transformer blocks", ^{
  auto transformerBlock =
      ^(NSDictionary<NSString *, id> *, INTAppContext *, INTEventMetadata *metadata, id) {
        return intl::TransformerBlockResult(nil, @[metadata]);
      };

  auto transformer = [[INTEventTransformer alloc] initWithTransformerBlocks:{
    transformerBlock
  }];

  auto metadata1 =
      [[INTEventMetadata alloc] initWithTotalRunTime:1 foregroundRunTime:1
                                     deviceTimestamp:[NSDate date] eventID:[NSUUID UUID]];

  auto metadata2 =
      [[INTEventMetadata alloc] initWithTotalRunTime:2 foregroundRunTime:2
                                     deviceTimestamp:[NSDate date] eventID:[NSUUID UUID]];

  expect([transformer processEvent:@"foo" metadata:metadata1 appContext:@{}])
      .to.equal(@[metadata1]);
  expect([transformer processEvent:@"bar" metadata:metadata2 appContext:@{}])
      .to.equal(@[metadata2]);
});

it(@"should pass app context to transformer blocks", ^{
  auto transformerBlock =
      ^(NSDictionary<NSString *, id> *, INTAppContext *context, INTEventMetadata *, id) {
        return intl::TransformerBlockResult(nil, @[context]);
      };

  auto transformer = [[INTEventTransformer alloc] initWithTransformerBlocks:{
    transformerBlock
  }];

  auto context1 = @{
    @"foo": @"bar",
    @"baz": @1
  };

  auto context2 = @{
    @"bar": @"foo",
    @"que": @1
  };

  expect([transformer processEvent:@"foo" metadata:metadata appContext:context1])
      .to.equal(@[context1]);
  expect([transformer processEvent:@"bar" metadata:metadata appContext:context2])
      .to.equal(@[context2]);
});

it(@"should return all transformed events from all trasformer blocks", ^{
  auto transformerBlock1 =
      ^(NSDictionary<NSString *, id> *, INTAppContext *, INTEventMetadata *, id) {
        return intl::TransformerBlockResult(nil, @[@"foo", @"baz"]);
      };

  auto transformerBlock2 =
      ^(NSDictionary<NSString *, id> *, INTAppContext *, INTEventMetadata *, id) {
        return intl::TransformerBlockResult(nil, @[@"bar"]);
      };

  auto transformer = [[INTEventTransformer alloc] initWithTransformerBlocks:{
    transformerBlock1,
    transformerBlock2
  }];

  auto events =
      [NSSet setWithArray:[transformer processEvent:@"foo" metadata:metadata appContext:@{}]];

  auto expected = [NSSet setWithArray:@[@"foo", @"bar", @"baz"]];
  expect(events).to.equal(expected);
});

SpecEnd
