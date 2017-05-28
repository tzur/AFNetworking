// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTEventsPipeline.h"

#import <Intelligence/INTDeviceTokenChangedEvent.h>
#import <LTKit/NSArray+Functional.h>

#import "INTAppLifecycleTimer.h"
#import "INTDataHelpers.h"
#import "INTDeviceInfo.h"
#import "INTDeviceInfoLoadedEvent.h"
#import "INTEventMetadata.h"
#import "INTRecorderLogger.h"

@interface INTFakeAppLifecycleTimer : NSObject <INTAppLifecycleTimer>
@property (readwrite, nonatomic) INTAppRunTimes appRunTimes;
@end

@implementation INTFakeAppLifecycleTimer
@end

SpecBegin(INTEventsPipeline)

__block INTFakeAppLifecycleTimer *timer;
__block INTRecorderLogger *logger;

beforeEach(^{
  timer = [[INTFakeAppLifecycleTimer alloc] init];
  logger = [[INTRecorderLogger alloc] init];
});

it(@"should log all transformed events from all trasformer blocks", ^{
  auto transformerBlock1 =
      ^(NSDictionary<NSString *, id> *, INTAppContext *, INTEventMetadata *, id) {
        return intl::TransformerBlockResult(nil, @[@"foo", @"baz"]);
      };

  auto transformerBlock2 =
      ^(NSDictionary<NSString *, id> *, INTAppContext *, INTEventMetadata *, id) {
        return intl::TransformerBlockResult(nil, @[@"bar"]);
      };

  auto intelligenceEvents = [[INTEventsPipeline alloc] initWithConfiguration:{
    .contextGeneratorBlock = INTIdentityAppContextGenerator(),
    .transformerBlocks = {
      transformerBlock1,
      transformerBlock2
    },
    .eventLoggers = @[logger],
    .appLifecycleTimer = timer
  }];

  [intelligenceEvents reportLowLevelEvent:@"que"];

  auto expected = [NSSet setWithArray:@[@"foo", @"bar", @"baz"]];
  expect([NSSet setWithArray:logger.eventsLogged]).will.equal(expected);
});

it(@"should not log unsupported events to loggers", ^{
  auto transformerBlock =
      ^(NSDictionary<NSString *, id> *, INTAppContext *, INTEventMetadata *, id) {
        return intl::TransformerBlockResult(nil, @[@"foo", @"baz"]);
      };

  INTRecorderLogger *logger = [[INTRecorderLogger alloc] initWithEventFilter:^BOOL(id event) {
    return ![event isEqual:@"foo"];
  }];

  auto intelligenceEvents = [[INTEventsPipeline alloc] initWithConfiguration:{
    .contextGeneratorBlock = INTIdentityAppContextGenerator(),
    .transformerBlocks = {transformerBlock},
    .eventLoggers = @[logger],
    .appLifecycleTimer = timer
  }];

  [intelligenceEvents reportLowLevelEvent:@"que"];

  expect(logger.eventsLogged).will.equal(@[@"baz"]);
});

context(@"metadata", ^{
  __block INTEventsPipeline *intelligenceEvents;
  __block INTAppContextGeneratorBlock contextGeneratorBlock;
  __block INTTransformerBlock transformerBlock;

  beforeEach(^{
    contextGeneratorBlock =
        ^(INTAppContext *, INTEventMetadata *metadata, id) {
          return @{@"metadata": metadata};
        };

    transformerBlock =
        ^(NSDictionary<NSString *, id> *, INTAppContext *context, INTEventMetadata *metadata, id) {
          if ([context[@"metadata"] isEqual:metadata]) {
            return intl::TransformerBlockResult(nil, @[metadata]);
          }

          return intl::TransformerBlockResult(nil, @[metadata]);
        };

    intelligenceEvents = [[INTEventsPipeline alloc] initWithConfiguration:{
      .contextGeneratorBlock = contextGeneratorBlock,
      .transformerBlocks = {transformerBlock},
      .eventLoggers = @[logger],
      .appLifecycleTimer = timer
    }];
  });

  it(@"should pass the same metadata to context generator and transformers", ^{
    [intelligenceEvents reportLowLevelEvent:@"foo"];

    expect(logger.eventsLogged).will.haveCount(1);
    expect(logger.eventsLogged.firstObject).will.beKindOf(INTEventMetadata.class);
  });

  it(@"should pass metadata with total run time from the app lifetime timer", ^{
    timer.appRunTimes = {4.6, 4.6};
    [intelligenceEvents reportLowLevelEvent:@"foo"];

    expect([logger.eventsLogged.firstObject totalRunTime]).will.equal(4.6);
  });

  it(@"should pass metadata with total run time from the app lifetime timer", ^{
    timer.appRunTimes = {4.6, 4.6};
    [intelligenceEvents reportLowLevelEvent:@"foo"];

    expect([logger.eventsLogged.firstObject foregroundRunTime]).will.equal(4.6);
  });

  context(@"subsequent events", ^{
    beforeEach(^{
      waitUntil(^(DoneCallback done) {
        logger = [[INTRecorderLogger alloc] initWithNewEventBlock:^(NSArray *eventsLogged) {
          if (eventsLogged.count == 3) {
            done();
          }
        }];

        intelligenceEvents = [[INTEventsPipeline alloc] initWithConfiguration:{
          .contextGeneratorBlock = contextGeneratorBlock,
          .transformerBlocks = {transformerBlock},
          .eventLoggers = @[logger],
          .appLifecycleTimer = timer
        }];

        [intelligenceEvents reportLowLevelEvent:@"foo"];
        [intelligenceEvents reportLowLevelEvent:@"foo"];
        [intelligenceEvents reportLowLevelEvent:@"foo"];
      });
    });

    it(@"should increase device timestamp for subsequent events", ^{
      auto timestamps = [logger.eventsLogged lt_map:^id(INTEventMetadata *meta) {
        return @([meta.deviceTimestamp timeIntervalSinceReferenceDate]);
      }];

      auto orderedTimestamps = [timestamps sortedArrayUsingSelector:@selector(compare:)];

      expect(timestamps).to.equal(orderedTimestamps);
    });

    it(@"should have unique event id for different events", ^{
      expect([NSSet setWithArray:logger.eventsLogged]).to.haveCount(3);
    });
  });
});

it(@"should store returned context from context generator", ^{
  INTAppContextGeneratorBlock contextGeneratorBlock =
      ^(INTAppContext *context, INTEventMetadata *, id) {
        NSUInteger counter = [context[@"counter"] unsignedIntegerValue];

        return @{@"counter": @(counter + 1)};
      };
  INTTransformerBlock transformerBlock =
      ^(NSDictionary<NSString *, id> *, INTAppContext *context, INTEventMetadata *, id) {
          return intl::TransformerBlockResult(nil, @[context[@"counter"]]);
      };

  INTEventsPipeline *intelligenceEvents = [[INTEventsPipeline alloc] initWithConfiguration:{
    .contextGeneratorBlock = contextGeneratorBlock,
    .transformerBlocks = {transformerBlock},
    .eventLoggers = @[logger],
    .appLifecycleTimer = timer
  }];

  [intelligenceEvents reportLowLevelEvent:@"foo"];
  [intelligenceEvents reportLowLevelEvent:@"foo"];

  expect(logger.eventsLogged).will.equal(@[@1, @2]);
});

it(@"should report device info loaded events", ^{
  auto passThroughTransformerBlock =
      ^(NSDictionary<NSString *, id> *, INTAppContext *, INTEventMetadata *, id event) {
        return intl::TransformerBlockResult(nil, @[event]);
      };

  auto intelligenceEvents = [[INTEventsPipeline alloc] initWithConfiguration:{
    .contextGeneratorBlock = INTIdentityAppContextGenerator(),
    .transformerBlocks = {
      passThroughTransformerBlock
    },
    .eventLoggers = @[logger],
    .appLifecycleTimer = timer
  }];

  INTDeviceInfo *deviceInfo = OCMClassMock(INTDeviceInfo.class);
  auto deviceInfoRevisionID = [NSUUID UUID];

  [intelligenceEvents deviceInfoObserver:OCMClassMock(INTDeviceInfoObserver.class)
                        loadedDeviceInfo:deviceInfo deviceInfoRevisionID:deviceInfoRevisionID
                           isNewRevision:YES];

  auto expected = @[[[INTDeviceInfoLoadedEvent alloc] initWithDeviceInfo:deviceInfo
                                                    deviceInfoRevisionID:deviceInfoRevisionID
                                                           isNewRevision:YES]];
  expect(logger.eventsLogged).will.equal(expected);
});

it(@"should report device token changed events", ^{
  auto passThroughTransformerBlock =
      ^(NSDictionary<NSString *, id> *, INTAppContext *, INTEventMetadata *, id event) {
        return intl::TransformerBlockResult(nil, @[event]);
      };

  auto intelligenceEvents = [[INTEventsPipeline alloc] initWithConfiguration:{
    .contextGeneratorBlock = INTIdentityAppContextGenerator(),
    .transformerBlocks = {
      passThroughTransformerBlock
    },
    .eventLoggers = @[logger],
    .appLifecycleTimer = timer
  }];

  auto deviceToken =
      INTVectorToNSData<unsigned char>({0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef});
  [intelligenceEvents deviceTokenDidChange:deviceToken];
  [intelligenceEvents deviceTokenDidChange:nil];

  auto expected = @[
    [[INTDeviceTokenChangedEvent alloc] initWithDeviceToken:@"0123456789ABCDEF"],
    [[INTDeviceTokenChangedEvent alloc] initWithDeviceToken:nil]
  ];

  expect(logger.eventsLogged).will.equal(expected);
});

SpecEnd
