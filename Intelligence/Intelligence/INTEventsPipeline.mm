// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTEventsPipeline.h"

#import <LTKit/NSData+HexString.h>

#import "INTAnalytricksSubscriptionInfoChanged.h"
#import "INTAppRunCountUpdatedEvent.h"
#import "INTDeviceInfoLoadedEvent.h"
#import "INTDeviceTokenChangedEvent.h"
#import "INTEventLogger.h"
#import "INTEventMetadata.h"
#import "INTEventTransformer.h"
#import "INTSubscriptionInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface INTEventsPipeline ()

/// Application context generator block, used for generating context when low level events are
/// reported.
@property (readonly, nonatomic) INTAppContextGeneratorBlock contextGenerator;

/// Event transformer for transforming low level events to high level events.
@property (readonly, nonatomic) INTEventTransformer *eventTransformer;

/// Event loggers, used for logging high level events.
@property (readonly, nonatomic) NSArray<id<INTEventLogger>> *eventLoggers;

/// App lifecycle timer for fetching total run time and foreground run time of the application.
@property (readonly, nonatomic) id<INTAppLifecycleTimer> appLifecycleTimer;

/// Current analytics context.
@property (strong, nonatomic) INTAppContext *appContext;

/// Queue for thread safe processing of events and asynchronous processing of events.
@property (readonly, nonatomic) dispatch_queue_t pipelineQueue;

@end

@implementation INTEventsPipeline

- (instancetype)initWithConfiguration:(const INTEventsPipelineConfiguration &)configuration {
  if (self = [super init]) {
    @synchronized (self) {
      _contextGenerator = configuration.contextGeneratorBlock;
      _appLifecycleTimer = configuration.appLifecycleTimer;
      _appContext = @{};
      _pipelineQueue = dispatch_queue_create("com.lightricks.Intelligence.INTEventsPipeline",
                                             DISPATCH_QUEUE_SERIAL);
    }

    _eventTransformer =
        [[INTEventTransformer alloc] initWithTransformerBlocks:configuration.transformerBlocks];
    _eventLoggers = configuration.eventLoggers;
  }
  return self;
}

- (void)reportLowLevelEvent:(id)event {
  @synchronized (self) {
    auto appRunTimes = self.appLifecycleTimer.appRunTimes;
    INTEventMetadata *metadata =
        [[INTEventMetadata alloc] initWithTotalRunTime:appRunTimes.totalRunTime
                                     foregroundRunTime:appRunTimes.foregroundRunTime
                                       deviceTimestamp:[NSDate date] eventID:[NSUUID UUID]];

    self.appContext = self.contextGenerator(self.appContext, metadata, event);

    // The pipeline should use the current \c self.appContext. It is copied to a local variable
    // because the block following it, is asynchronous, and \c self.appContext may change before
    // it's called by a consecutive call to <tt>-[INTEventsPipeline reportLowLevelEvent:]</tt>.
    auto appContext = self.appContext;
    dispatch_async(self.pipelineQueue, ^{
      auto highLevelEvents = [self.eventTransformer processEvent:event metadata:metadata
                                                      appContext:appContext];

      for (id highLevelEvent in highLevelEvents) {
        [self logEvent:highLevelEvent];
      }
    });
  }
}

- (void)logEvent:(id)event {
  for (id<INTEventLogger> eventLogger in self.eventLoggers) {
    if ([eventLogger isEventSupported:event]) {
      [eventLogger logEvent:event];
    }
  }
}

#pragma mark -
#pragma mark INTDeviceInfoManagerDelegate
#pragma mark -

- (void)deviceInfoObserver:(INTDeviceInfoObserver * __unused)deviceInfoObserver
          loadedDeviceInfo:(INTDeviceInfo *)deviceInfo
      deviceInfoRevisionID:(NSUUID *)deviceInfoRevisionID
             isNewRevision:(BOOL)isNewRevision {
  [self reportLowLevelEvent:[[INTDeviceInfoLoadedEvent alloc]
                             initWithDeviceInfo:deviceInfo deviceInfoRevisionID:deviceInfoRevisionID
                             isNewRevision:isNewRevision]];
}

- (void)deviceTokenDidChange:(nullable NSData *)deviceToken {
  [self reportLowLevelEvent:[[INTDeviceTokenChangedEvent alloc]
                             initWithDeviceToken:[deviceToken lt_hexString]]];
}

- (void)appRunCountUpdated:(NSNumber *)runCount {
  [self reportLowLevelEvent:[[INTAppRunCountUpdatedEvent alloc] initWithRunCount:runCount]];
}

- (void)subscriptionInfoDidChanged:(nullable INTSubscriptionInfo *)subscriptionInfo {
  auto event = [[INTAnalytricksSubscriptionInfoChanged alloc]
                initWithIsAvailable:(subscriptionInfo != nil)
                subscriptionStatus:subscriptionInfo.subscriptionStatus.name
                productID:subscriptionInfo.productID transactionID:subscriptionInfo.transactionID
                purchaseDate:subscriptionInfo.purchaseDate
                expirationDate:subscriptionInfo.expirationDate
                cancellationDate:subscriptionInfo.cancellationDate];

  [self reportLowLevelEvent:event];
}

@end

NS_ASSUME_NONNULL_END
