// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRExternalTriggerReceiptValidator.h"

#import "BZREvent.h"
#import "BZRReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRExternalTriggerReceiptValidator ()

/// Provider used to fetch receipt validation status.
@property (readonly, nonatomic) id<BZRReceiptValidationStatusProvider> validationStatusProvider;

/// Subscription to the trigger signal. Will be \c nil while deactivated and non-nil when activated.
@property (strong, nonatomic, nullable) RACDisposable *triggerSignalSubscription;

/// The other end of \c eventsSignal used to send validation errors.
@property (readonly, nonatomic) RACSubject *errorsSubject;

@end

@implementation BZRExternalTriggerReceiptValidator

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithValidationStatusProvider:
    (id<BZRReceiptValidationStatusProvider>)validationStatusProvider {
  if (self = [super init]) {
    _validationStatusProvider = validationStatusProvider;
    _errorsSubject = [RACSubject subject];
  }
  return self;
}

- (void)dealloc {
  [self deactivate];
}

#pragma mark -
#pragma mark BZREventEmitter
#pragma mark -

- (RACSignal *)eventsSignal {
  return [[self.errorsSubject
      map:^BZREvent *(NSError *error) {
        return [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error];
      }]
      takeUntil:[self rac_willDeallocSignal]];
}

#pragma mark -
#pragma mark Activating receipt validation
#pragma mark -

- (void)activateWithTrigger:(RACSignal *)triggerSignal {
  @synchronized (self) {
    [self deactivate];

    @weakify(self);
    self.triggerSignalSubscription = [triggerSignal subscribeNext:^(id) {
      @strongify(self);
      [self fetchReceiptValidationStatus];
    }];
  }
}

- (void)fetchReceiptValidationStatus {
  @weakify(self);
  [[self.validationStatusProvider fetchReceiptValidationStatus] subscribeError:^(NSError *error) {
    @strongify(self);
    [self.errorsSubject sendNext:error];
  }];
}

#pragma mark -
#pragma mark Deactivating receipt validation
#pragma mark -

- (void)deactivate {
  @synchronized (self) {
    if (self.triggerSignalSubscription) {
      [self.triggerSignalSubscription dispose];
      self.triggerSignalSubscription = nil;
    }
  }
}

@end

NS_ASSUME_NONNULL_END
