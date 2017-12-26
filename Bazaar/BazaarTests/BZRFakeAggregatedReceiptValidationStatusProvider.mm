// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRFakeAggregatedReceiptValidationStatusProvider.h"

#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRMultiAppReceiptValidationStatusAggregator.h"
#import "BZRReceiptValidationStatusCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRFakeAggregatedReceiptValidationStatusProvider ()

/// \c YES if \c fetchReceiptValidationStatus was called, \c NO otherwise.
@property (readwrite, nonatomic) BOOL wasFetchReceiptValidationStatusCalled;

/// \c YES if \c expireSubscription was called, \c NO otherwise.
@property (readwrite, nonatomic) BOOL wasExpireSubscriptionCalled;

@end

@implementation BZRFakeAggregatedReceiptValidationStatusProvider

@synthesize receiptValidationStatus = _receiptValidationStatus;

- (instancetype)init {
  BZRCachedReceiptValidationStatusProvider *provider =
      OCMClassMock([BZRCachedReceiptValidationStatusProvider class]);
  OCMStub([provider eventsSignal]).andReturn([RACSignal empty]);
  BZRMultiAppReceiptValidationStatusAggregator *aggregator =
      OCMClassMock([BZRMultiAppReceiptValidationStatusAggregator class]);
  BZRReceiptValidationStatusCache *cache = OCMClassMock([BZRReceiptValidationStatusCache class]);
  OCMStub([provider receiptValidationStatusCache]).andReturn(cache);

  return [super initWithUnderlyingProvider:provider aggregator:aggregator
                    bundledApplicationsIDs:@[@"foo", @"bar"].lt_set];
}

- (RACSignal *)fetchReceiptValidationStatus {
  self.wasFetchReceiptValidationStatusCalled = YES;
  return self.signalToReturnFromFetchReceiptValidationStatus ?: [RACSignal empty];
}

@end

NS_ASSUME_NONNULL_END
