// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPeriodicReceiptValidator.h"

#import "BZRReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRPeriodicReceiptValidator ()

/// Provider used to fetch receipt validation status.
@property (readonly, nonatomic) id<BZRReceiptValidationStatusProvider> receiptValidationProvider;

/// Subscription that checks if the receipt needs validation periodically.
@property (strong, nonatomic, nullable) RACDisposable *validationCheckSubscription;

/// The other end of \c errorsSignal used to send errors with.
@property (readonly, nonatomic) RACSubject *errorsSubject;

@end

@implementation BZRPeriodicReceiptValidator

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithReceiptValidationProvider:
    (id<BZRReceiptValidationStatusProvider>)receiptValidationProvider {
  if (self = [super init]) {
    _receiptValidationProvider = receiptValidationProvider;
    _errorsSubject = [RACSubject subject];
  }
  return self;
}

#pragma mark -
#pragma mark Errors signal
#pragma mark -

- (RACSignal *)errorsSignal {
  return [self.errorsSubject takeUntil:[self rac_willDeallocSignal]];
}

#pragma mark -
#pragma mark Activating periodic validation check
#pragma mark -

- (void)activatePeriodicValidationCheck:(RACSignal *)validateReceiptSignal {
  @weakify(self)
  self.validationCheckSubscription = [validateReceiptSignal subscribeNext:^(id) {
    @strongify(self);
    [[self.receiptValidationProvider fetchReceiptValidationStatus]
        subscribeError:^(NSError *error) {
          [self.errorsSubject sendNext:error];
        }];
  }];
}

#pragma mark -
#pragma mark Deactivating periodic validation check
#pragma mark -

- (void)deactivatePeriodicValidationCheck {
  [self.validationCheckSubscription dispose];
}

@end

NS_ASSUME_NONNULL_END
