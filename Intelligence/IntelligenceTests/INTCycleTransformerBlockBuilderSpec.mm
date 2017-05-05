// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTCycleTransformerBlockBuilder.h"

#import "INTEventMetadata.h"
#import "INTEventTransformationExecutor.h"

SpecBegin(INTCyclicTransformerBlockBuilder)

INTEventIdentifierBlock kNSStringEventIdentifier = ^NSString * _Nullable(NSString *event) {
  if (![event isKindOfClass:NSString.class]) {
    return nil;
  }

  return event;
};

it(@"should invoke onCycleEnd block at the end of a cycle", ^{
  auto transformerBlock = INTCycleTransformerBuilder(kNSStringEventIdentifier)
      .cycle(@"baz", @"que")
      .onCycleEnd(^(NSDictionary<NSString *, id> *) {
        return @[@"foo", @"bar"];
      })
      .build();

  auto eventSequence = @[
    INTEventTransformerArgs(@"baz", INTCreateEventMetadata(), @{}),
    INTEventTransformerArgs(@"que", INTCreateEventMetadata(1), @{}),
    INTEventTransformerArgs(@"baz", INTCreateEventMetadata(2), @{}),
    INTEventTransformerArgs(@"que", INTCreateEventMetadata(3), @{}),
  ];

  auto expectedEvents = @[@"foo", @"bar", @"foo", @"bar"];

  auto executor =
      [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];

  expect([executor transformEventSequence:eventSequence]).to.equal(expectedEvents);
});

it(@"should not complete transformation if cycle had not started", ^{
  auto transformerBlock = INTCycleTransformerBuilder(kNSStringEventIdentifier)
      .cycle(@"baz", @"que")
      .onCycleEnd(^(NSDictionary<NSString *, id> *) {
        return @[@"foo", @"bar"];
      })
      .build();

  auto eventSequence = @[
    INTEventTransformerArgs(@"que", INTCreateEventMetadata(1), @{}),
  ];

  auto executor =
      [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];

  expect([executor transformEventSequence:eventSequence]).to.beEmpty();
});

it(@"should recover after an unbalanced end event arrival", ^{
  auto transformerBlock = INTCycleTransformerBuilder(kNSStringEventIdentifier)
      .cycle(@"baz", @"que")
      .onCycleEnd(^(NSDictionary<NSString *, id> *aggregatedData) {
        return @[
          aggregatedData[kINTCycleDurationKey],
          aggregatedData[kINTStartMetadataKey],
          aggregatedData[kINTStartContextKey]
        ];
      })
      .build();

  auto startMetadata = INTCreateEventMetadata(2);
  auto startContext = @{@"que": @4};
  auto eventSequence = @[
    INTEventTransformerArgs(@"que", INTCreateEventMetadata(1), @{}),
    INTEventTransformerArgs(@"baz", startMetadata, startContext),
    INTEventTransformerArgs(@"que", INTCreateEventMetadata(4), @{})
  ];

  auto executor =
      [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];

  expect([executor transformEventSequence:eventSequence]).equal(@[@2, startMetadata, startContext]);
});

it(@"should aggregate data using aggregation blocks", ^{
  auto transformerBlock = INTCycleTransformerBuilder(kNSStringEventIdentifier)
      .cycle(@"foo", @"baz")
      .aggregate(@"foo", ^(NSDictionary<NSString *, id> *aggregatedData, NSString *) {
        NSUInteger counter = [aggregatedData[@"counter"] unsignedIntegerValue];
        return @{@"counter": @(counter + 1)};
      })
      .aggregate(@"bar", ^(NSDictionary<NSString *, id> *aggregatedData, NSString *) {
        NSUInteger counter = [aggregatedData[@"counter"] unsignedIntegerValue];
        return @{@"counter": @(counter + 1)};
      })
      .onCycleEnd(^(NSDictionary<NSString *, id> *aggregatedData) {
        return @[
          aggregatedData[@"counter"],
          aggregatedData[kINTCycleDurationKey],
          aggregatedData[kINTStartMetadataKey],
          aggregatedData[kINTStartContextKey]
        ];
      })
      .build();

  auto startMetadata = INTCreateEventMetadata();
  auto startContext = @{@"que": @4};
  auto eventSequence = @[
    INTEventTransformerArgs(@"foo", startMetadata, startContext),
    INTEventTransformerArgs(@"bar", INTCreateEventMetadata(1)),
    INTEventTransformerArgs(@"bar", INTCreateEventMetadata(2)),
    INTEventTransformerArgs(@"baz", INTCreateEventMetadata(5)),
  ];

  auto executor =
      [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];

  auto expected = @[@3, @5, startMetadata, startContext];
  expect([executor transformEventSequence:eventSequence]).to.equal(expected);
});

it(@"should pass metadata to aggregation blocks", ^{
  auto transformerBlock = INTCycleTransformerBuilder(kNSStringEventIdentifier)
      .cycle(@"foo", @"bar")
      .aggregate(@"foo", ^(NSDictionary<NSString *, id> *, NSString *, INTEventMetadata *metadata) {
        return @{@"metadata1": metadata};
      })
      .aggregate(@"bar", ^(NSDictionary<NSString *, id> *, NSString *, INTEventMetadata *metadata) {
        return @{@"metadata2": metadata};
      })
      .onCycleEnd(^(NSDictionary<NSString *, id> *aggregatedData) {
        return @[aggregatedData[@"metadata1"], aggregatedData[@"metadata2"]];
      })
      .build();

  auto metadata1 = INTCreateEventMetadata(34.2);
  auto metadata2 = INTCreateEventMetadata(2.3);

  auto eventSequence = @[
    INTEventTransformerArgs(@"foo", metadata1),
    INTEventTransformerArgs(@"bar", metadata2),
  ];

  auto executor =
      [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];

  expect([executor transformEventSequence:eventSequence]).to.equal(@[metadata1, metadata2]);
});

it(@"should pass application context to aggregation blocks", ^{
  auto transformerBlock = INTCycleTransformerBuilder(kNSStringEventIdentifier)
      .cycle(@"foo", @"bar")
      .aggregate(@"foo", ^(NSDictionary<NSString *, id> *, NSString *, INTEventMetadata *,
                           INTAppContext *context) {
        return @{@"context1": context};
      })
      .aggregate(@"bar", ^(NSDictionary<NSString *, id> *, NSString *, INTEventMetadata *,
                           INTAppContext *context) {
        return @{@"context2": context};
      })
      .onCycleEnd(^(NSDictionary<NSString *, id> *aggregatedData) {
        return @[aggregatedData[@"context1"], aggregatedData[@"context2"]];
      })
      .build();

  auto context1 = @{@"baz": @2};
  auto context2 = @{@"que": @"thus"};

  auto eventSequence = @[
    INTEventTransformerArgs(@"foo", INTCreateEventMetadata(), context1),
    INTEventTransformerArgs(@"bar", INTCreateEventMetadata(), context2),
  ];

  auto executor =
      [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];

  expect([executor transformEventSequence:eventSequence]).to.equal(@[context1, context2]);
});

it(@"should time event cycle", ^{
  auto transformerBlock = INTCycleTransformerBuilder(kNSStringEventIdentifier)
      .cycle(@"foo", @"bar")
      .onCycleEnd(^(NSDictionary<NSString *, id> *aggregatedData) {
        return @[aggregatedData[kINTCycleDurationKey]];
      })
      .build();

  auto eventSequence = @[
    INTEventTransformerArgs(@"foo", INTCreateEventMetadata(3)),
    INTEventTransformerArgs(@"bar", INTCreateEventMetadata(7)),
    INTEventTransformerArgs(@"foo", INTCreateEventMetadata(8.5)),
    INTEventTransformerArgs(@"bar", INTCreateEventMetadata(13))
  ];

  auto executor =
      [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];

  auto expected = @[@4, @4.5];

  expect([executor transformEventSequence:eventSequence]).to.equal(expected);
});

it(@"should aggregate start event context", ^{
  auto transformerBlock = INTCycleTransformerBuilder(kNSStringEventIdentifier)
      .cycle(@"foo", @"bar")
      .onCycleEnd(^(NSDictionary<NSString *, id> *aggregatedData) {
        return @[aggregatedData[kINTStartContextKey]];
      })
      .build();

  auto startContext1 = @{@"baz": @1};
  auto startContext2 = @{@"que": @4};
  auto eventSequence = @[
    INTEventTransformerArgs(@"foo", INTCreateEventMetadata(), startContext1),
    INTEventTransformerArgs(@"bar", INTCreateEventMetadata()),
    INTEventTransformerArgs(@"foo", INTCreateEventMetadata(), startContext2),
    INTEventTransformerArgs(@"bar", INTCreateEventMetadata())
  ];

  auto executor =
      [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];

  auto expected = @[startContext1, startContext2];

  expect([executor transformEventSequence:eventSequence]).to.equal(expected);
});

it(@"should aggregate start event metadata", ^{
  auto transformerBlock = INTCycleTransformerBuilder(kNSStringEventIdentifier)
      .cycle(@"foo", @"bar")
      .onCycleEnd(^(NSDictionary<NSString *, id> *aggregatedData) {
        return @[aggregatedData[kINTStartMetadataKey]];
      })
      .build();

  auto startMetadata1 = INTCreateEventMetadata(45);
  auto startMetadata2 = INTCreateEventMetadata(33, 56);
  auto eventSequence = @[
    INTEventTransformerArgs(@"foo", startMetadata1),
    INTEventTransformerArgs(@"bar", INTCreateEventMetadata(7)),
    INTEventTransformerArgs(@"foo", startMetadata2),
    INTEventTransformerArgs(@"bar", INTCreateEventMetadata(13))
  ];

  auto executor =
      [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];

  auto expected = @[startMetadata1, startMetadata2];

  expect([executor transformEventSequence:eventSequence]).to.equal(expected);
});

SpecEnd
