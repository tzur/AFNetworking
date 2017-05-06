// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksTransformerBlockExamples.h"

#import <Intelligence/INTAnalytricksBaseUsage.h>
#import <Intelligence/INTAnalytricksContext.h>
#import <Intelligence/INTAnalytricksMetadata.h>
#import <LTKit/NSArray+Functional.h>

#import "INTAnalytricksContextGenerators.h"
#import "INTEventTransformationExecutor.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kINTAnalytricksBaseUsageTransformerBlockExamples =
    @"AnalytricksBaseUsageTransformerBlockExamples";
NSString * const kINTAnalytricksBaseUsageTransformerBlock =
    @"AnalytricksBaseUsageTransformerBlock";
NSString * const kINTAnalytricksEventTransformerArgumentsSequence =
    @"AnalytricksEventTransformerArgumentsSequence";
NSString * const kINTExpectedAnalytricksBaseUsageDataProviders =
    @"ExpectedAnalytricksBaseUsageDataProviders";
NSString * const kINTCycleStartIndices = @"INTCycleStartIndices";
NSString * const kINTShouldUseStartContext = @"ShouldUseStartContex";
NSString * const kINTShouldUseStartMetadata = @"ShouldUseStartMetadata";

SharedExampleGroupsBegin(kINTAnalytricksBaseUsageTransformerBlockExamples)

sharedExamplesFor(kINTAnalytricksBaseUsageTransformerBlockExamples, ^(NSDictionary *data) {
  __block INTEventTransformationExecutor *executor;
  __block INTTransformerBlock transformerBlock;
  __block NSArray<INTEventTransformerArguments *> *eventSequence;
  __block NSArray<NSNumber *> *cycleStartIndices;
  __block BOOL shouldUseStartContext;
  __block BOOL shouldUseStartMetadata;

  beforeEach(^{
    transformerBlock = data[kINTAnalytricksBaseUsageTransformerBlock];
    executor = [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];
    eventSequence = data[kINTAnalytricksEventTransformerArgumentsSequence];
    shouldUseStartContext = [data[kINTShouldUseStartContext] boolValue];
    shouldUseStartMetadata = [data[kINTShouldUseStartMetadata] boolValue];
    cycleStartIndices = data[kINTCycleStartIndices] ?: @[@0];

    eventSequence =
        [eventSequence lt_map:^(INTEventTransformerArguments *arguments) {
          auto screenName = @"foo";
          auto analytricksContext =
              [[INTAnalytricksContext alloc]
               initWithRunID:[NSUUID UUID] sessionID:[NSUUID UUID] screenUsageID:[NSUUID UUID]
               screenName:screenName openProjectID:[NSUUID UUID]];

          NSMutableDictionary *context = [arguments.context mutableCopy];
          context[kINTAppContextAnalytricksContextKey] = analytricksContext;
          context[kINTAppContextDeviceIDKey] = [NSUUID UUID];
          context[kINTAppContextDeviceInfoIDKey] = [NSUUID UUID];
          return INTEventTransformerArgs(arguments.event, arguments.metadata, context);
        }];
  });

  it(@"should produce transform events into analytrics usage events", ^{
    INTAppContext *startContext = nil;
    INTEventMetadata *startMetadata = nil;

    intl::TransformerBlockResult result(@{}, @[]);
    for (NSUInteger i = 0; i < eventSequence.count; ++i) {
      if (!([cycleStartIndices indexOfObject:@(i)] == NSNotFound)) {
        startContext = eventSequence[i].context;
        startMetadata = eventSequence[i].metadata;
      }

      result = transformerBlock(result.aggregatedData, eventSequence[i].context,
                                eventSequence[i].metadata, eventSequence[i].event);

      if (!result.highLevelEvents.count) {
        continue;
      }

      INTAppContext *appContext =
          shouldUseStartContext ? startContext : eventSequence[i].context;

      INTAnalytricksContext *analytricksContext =
          appContext[kINTAppContextAnalytricksContextKey];

      NSUUID *ltDeviceID = appContext[kINTAppContextDeviceIDKey];
      NSUUID *deviceInfoID = appContext[kINTAppContextDeviceInfoIDKey];

      INTEventMetadata *eventMetadata =
          shouldUseStartMetadata ? startMetadata : eventSequence[i].metadata;

      auto analytricksMetadata =
          [[INTAnalytricksMetadata alloc]
           initWithEventID:eventMetadata.eventID deviceTimestamp:eventMetadata.deviceTimestamp
           appTotalRunTime:@(eventMetadata.totalRunTime) ltDeviceID:ltDeviceID
           deviceInfoID:deviceInfoID];

      for (INTAnalytricksBaseUsage *event in result.highLevelEvents) {
        expect(event.INTAnalytricksContext).to.equal(analytricksContext);
        expect(event.INTAnalytricksMetadata).to.equal(analytricksMetadata);
      }
    }
  });

  it(@"should produce expected analytricks base usage data providers", ^{
    auto providers = [[executor transformEventSequence:eventSequence]
                      lt_map:^(INTAnalytricksBaseUsage *event) {
                        return event.dataProvider;
                      }];

    expect(providers).to.equal(data[kINTExpectedAnalytricksBaseUsageDataProviders]);
  });

  it(@"should not transform events if analytrics context is missing", ^{
    eventSequence =
        [eventSequence lt_map:^(INTEventTransformerArguments *arguments) {
          NSMutableDictionary *context = [arguments.context mutableCopy];
          [context removeObjectForKey:kINTAppContextAnalytricksContextKey];
          return INTEventTransformerArgs(arguments.event, arguments.metadata, context);
        }];

    expect([executor transformEventSequence:eventSequence]).to.haveCount(0);
  });

  it(@"should not transform events if device id is missing", ^{
    eventSequence = [eventSequence lt_map:^(INTEventTransformerArguments *arguments) {
      NSMutableDictionary *context = [arguments.context mutableCopy];
      [context removeObjectForKey:kINTAppContextDeviceIDKey];
      return INTEventTransformerArgs(arguments.event, arguments.metadata, context);
    }];

    expect([executor transformEventSequence:eventSequence]).to.haveCount(0);
  });

  it(@"should not transform events if device info id is missing", ^{
    eventSequence = [eventSequence lt_map:^(INTEventTransformerArguments *arguments) {
      NSMutableDictionary *context = [arguments.context mutableCopy];
      [context removeObjectForKey:kINTAppContextDeviceInfoIDKey];
      return INTEventTransformerArgs(arguments.event, arguments.metadata, context);
    }];

    expect([executor transformEventSequence:eventSequence]).to.haveCount(0);
  });
});

SharedExampleGroupsEnd

NS_ASSUME_NONNULL_END
