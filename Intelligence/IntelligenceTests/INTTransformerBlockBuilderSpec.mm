// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTTransformerBlockBuilder.h"

#import "INTEventMetadata.h"
#import "INTEventTransformationExecutor.h"

SpecBegin(INTTransformerBlockBuilder)

static INTEventIdentifierBlock kNSStringEventIdentifier = ^NSString * _Nullable(NSString *event) {
  if (![event isKindOfClass:NSString.class]) {
    return nil;
  }

  return event;
};

context(@"aggreration", ^{
  it(@"should update aggregated data", ^{
    auto transformerBlock = INTTransformerBuilder(kNSStringEventIdentifier)
        .aggregate(@"foo", ^(NSDictionary<NSString *, id> *aggregatedData, NSString *) {
          NSUInteger counter = [aggregatedData[@"counter"] unsignedIntegerValue];
          return @{@"counter": @(counter + 1)};
        })
        .aggregate(@"bar", ^(NSDictionary<NSString *, id> *aggregatedData, NSString *) {
          NSUInteger counter = [aggregatedData[@"counter2"] unsignedIntegerValue] ?: 1;
          return @{@"counter2": @(counter * 2)};
        })
        .build();

    auto result = transformerBlock(@{}, @{}, INTCreateEventMetadata(), @"foo");
    result = transformerBlock(result.aggregatedData, @{}, INTCreateEventMetadata(), @"bar");
    result = transformerBlock(result.aggregatedData, @{}, INTCreateEventMetadata(), @"bar");
    result = transformerBlock(result.aggregatedData, @{}, INTCreateEventMetadata(), @"foo");

    expect(result.aggregatedData).to.equal(@{
      @"counter": @2,
      @"counter2": @4
    });
  });

  it(@"should pass metadata to aggregation block", ^{
    auto transformerBlock = INTTransformerBuilder(kNSStringEventIdentifier)
        .aggregate(@"foo", ^(NSDictionary<NSString *, id> *, id, INTEventMetadata *metadata,
                             INTAppContext *) {
          return @{@"metadata1": metadata};
        })
        .aggregate(@"bar", ^(NSDictionary<NSString *, id> *, id, INTEventMetadata *metadata,
                             INTAppContext *) {
          return @{@"metadata2": metadata};
        })
        .build();

    auto metadata1 = INTCreateEventMetadata(2.3);
    auto result = transformerBlock(@{}, @{}, metadata1, @"foo");
    auto metadata2 = INTCreateEventMetadata(5.5);
    result = transformerBlock(result.aggregatedData, @{}, metadata2, @"bar");

    expect(result.aggregatedData).to.equal(@{
      @"metadata1": metadata1,
      @"metadata2": metadata2
    });
  });

  it(@"should pass application context to aggregation block", ^{
    auto transformerBlock = INTTransformerBuilder(kNSStringEventIdentifier)
        .aggregate(@"foo", ^(NSDictionary<NSString *, id> *, id, INTEventMetadata *,
                             INTAppContext *context) {
          return @{@"context1": context};
        })
        .aggregate(@"bar", ^(NSDictionary<NSString *, id> *, id, INTEventMetadata *,
                             INTAppContext *context) {
          return @{@"context2": context};
        })
        .build();

    auto context1 = @{@"baz": @20};
    auto result = transformerBlock(@{}, context1, INTCreateEventMetadata(), @"foo");
    auto context2 = @{@"que": @"thud"};
    result = transformerBlock(result.aggregatedData, context2, INTCreateEventMetadata(), @"bar");

    expect(result.aggregatedData).to.equal(@{
      @"context1": context1,
      @"context2": context2
    });
  });
});

context(@"transformation completion", ^{
  it(@"should complete transform using passed aggregated data", ^{
    auto transformerBlock = INTTransformerBuilder(kNSStringEventIdentifier)
        .transform(@"foo", ^(NSDictionary<NSString *, id> *aggregatedData) {
          return @[aggregatedData[@"bar"]];
        })
        .build();

    auto result = transformerBlock(@{@"bar": @4}, @{}, INTCreateEventMetadata(), @"foo");

    expect(result.highLevelEvents).to.equal(@[@4]);
  });

  it(@"should pass application context to completion blocks", ^{
    auto transformerBlock = INTTransformerBuilder(kNSStringEventIdentifier)
        .transform(@"foo", ^(NSDictionary<NSString *, id> *, id, INTEventMetadata *,
                             INTAppContext *context) {
          return @[context];
        })
        .transform(@"foo", ^(NSDictionary<NSString *, id> *, id, INTEventMetadata *,
                             INTAppContext *context) {
          return @[context];
        })
        .transform(@"bar", ^(NSDictionary<NSString *, id> *, id, INTEventMetadata *,
                             INTAppContext *context) {
          return @[context];
        })
        .build();

    auto executor =
        [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];

    auto context1 = @{@"baz": @34};
    auto context2 = @{@"thud": @45};

    auto highLevelEvents = [executor transformEventSequence:@[
      INTEventTransformerArgs(@"foo", INTCreateEventMetadata(), context1),
      INTEventTransformerArgs(@"bar", INTCreateEventMetadata(), context2)
    ]];

    expect(highLevelEvents).to.equal(@[context1, context1, context2]);
  });

  it(@"should pass application metadata to completion blocks", ^{
    auto transformerBlock = INTTransformerBuilder(kNSStringEventIdentifier)
        .transform(@"foo", ^(NSDictionary<NSString *, id> *, id, INTEventMetadata *metadata,
                             INTAppContext *) {
          return @[metadata];
        })
        .transform(@"foo", ^(NSDictionary<NSString *, id> *, id, INTEventMetadata *metadata,
                             INTAppContext *) {
          return @[metadata];
        })
        .transform(@"bar", ^(NSDictionary<NSString *, id> *, id, INTEventMetadata *metadata,
                             INTAppContext *) {
          return @[metadata];
        })
        .build();

    auto executor =
        [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];

    auto metadata1 = INTCreateEventMetadata(34);
    auto metadata2 = INTCreateEventMetadata(55);

    auto highLevelEvents = [executor transformEventSequence:@[
      INTEventTransformerArgs(@"foo", metadata1),
      INTEventTransformerArgs(@"bar", metadata2)
    ]];

    expect(highLevelEvents).to.equal(@[metadata1, metadata1, metadata2]);
  });

  it(@"should complete transform using passed aggregated data", ^{
    auto transformerBlock = INTTransformerBuilder(kNSStringEventIdentifier)
        .transform(@"foo", ^(NSDictionary<NSString *, id> *aggregatedData) {
          return @[aggregatedData[@"bar"]];
        })
        .build();

    auto result = transformerBlock(@{@"bar": @4}, @{}, INTCreateEventMetadata(), @"foo");

    expect(result.highLevelEvents).to.equal(@[@4]);
  });

  it(@"should complete transform only after aggregations", ^{
    auto transformerBlock = INTTransformerBuilder(kNSStringEventIdentifier)
        .aggregate(@"foo", ^(NSDictionary<NSString *, id> *, NSString *) {
          return @{
            @"bar": @4
          };
        })
        .aggregate(@"foo", ^(NSDictionary<NSString *, id> *, NSString *) {
          return @{
            @"baz": @5
          };
        })
        .transform(@"foo", ^(NSDictionary<NSString *, id> *aggregatedData) {
          return @[aggregatedData[@"bar"]];
        })
        .transform(@"foo", ^(NSDictionary<NSString *, id> *aggregatedData) {
          return @[aggregatedData[@"baz"]];
        })
        .build();

    auto result = transformerBlock(@{}, @{}, INTCreateEventMetadata(), @"foo");

    expect([NSSet setWithArray:result.highLevelEvents]).to.equal([NSSet setWithArray:@[@4, @5]]);
  });
});

SpecEnd
