// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRExternalTriggerReceiptValidator.h"

#import "BZREvent.h"
#import "BZRMultiAppReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRExternalTriggerReceiptValidator ()

/// Provider used to fetch the aggregated receipt validation status.
@property (readonly, nonatomic) BZRMultiAppReceiptValidationStatusProvider
    *multiAppValidationStatusProvider;

/// Subscription to the trigger signal. Will be \c nil while deactivated and non-nil when activated.
@property (strong, nonatomic, nullable) RACDisposable *triggerSignalSubscription;

/// The other end of \c eventsSignal used to send validation errors.
@property (readonly, nonatomic) RACSubject<NSError *> *errorsSubject;

@end

@implementation BZRExternalTriggerReceiptValidator

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithValidationStatusProvider:
    (BZRMultiAppReceiptValidationStatusProvider *)multiAppValidationStatusProvider {
  if (self = [super init]) {
    _multiAppValidationStatusProvider = multiAppValidationStatusProvider;
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

- (RACSignal<BZREvent *> *)eventsSignal {
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
    self.triggerSignalSubscription = [[triggerSignal
        takeUntil:self.rac_willDeallocSignal]
        subscribeNext:^(id) {
          @strongify(self);
          [self fetchReceiptValidationStatus];
        }];
  }
}

- (void)fetchReceiptValidationStatus {
  @weakify(self);
  [[[self.multiAppValidationStatusProvider fetchReceiptValidationStatus]
      takeUntil:self.rac_willDeallocSignal]
      subscribeError:^(NSError *error) {
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
