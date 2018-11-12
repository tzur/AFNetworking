// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPeriodicReceiptValidatorActivator.h"

#import <LTKit/LTDateProvider.h>

#import "BZRExternalTriggerReceiptValidator.h"
#import "BZRReceiptValidationDateProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRPeriodicReceiptValidatorActivator ()

/// Validator that is activated and deactivated depending on the receipt validation status.
@property (readonly, nonatomic) BZRExternalTriggerReceiptValidator *receiptValidator;

/// Provider used to provide the current date.
@property (readonly, nonatomic) id<LTDateProvider> dateProvider;

/// Time between each periodic validation.
@property (readwrite, nonatomic) BZRReceiptValidationDateProvider *validationDateProvider;

@end

@implementation BZRPeriodicReceiptValidatorActivator

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithMultiAppValidationStatusProvider:
    (BZRMultiAppReceiptValidationStatusProvider *)multiAppReceiptValidationStatusProvider
    validationDateProvider:(id<BZRReceiptValidationDateProvider>)validationDateProvider
    dateProvider:(id<LTDateProvider>)dateProvider {
  BZRExternalTriggerReceiptValidator *receiptValidator =
      [[BZRExternalTriggerReceiptValidator alloc]
       initWithValidationStatusProvider:multiAppReceiptValidationStatusProvider];

   return [self initWithReceiptValidator:receiptValidator
                  validationDateProvider:validationDateProvider
                            dateProvider:dateProvider];
}

- (instancetype)initWithReceiptValidator:(BZRExternalTriggerReceiptValidator *)receiptValidator
    validationDateProvider:(id<BZRReceiptValidationDateProvider>)validationDateProvider
    dateProvider:(id<LTDateProvider>)dateProvider {
  if (self = [super init]) {
    _receiptValidator = receiptValidator;
    _validationDateProvider = validationDateProvider;
    _dateProvider = dateProvider;

    [self activatePeriodicValidation];
  }
  return self;
}

#pragma mark -
#pragma mark Activating/deactivating timer
#pragma mark -

- (void)activatePeriodicValidation {
  @weakify(self);
  [RACObserve(self.validationDateProvider, nextValidationDate)
      subscribeNext:^(NSDate * _Nullable nextValidationDate) {
        @strongify(self);
        if (!nextValidationDate) {
          [self.receiptValidator deactivate];
          return;
        }

        [self activatePeriodicValidation:nextValidationDate
                             currentTime:[self.dateProvider currentDate]];
      }];
}

- (void)activatePeriodicValidation:(NSDate *)nextValidationDate currentTime:(NSDate *)currentTime {
  auto timeToNextValidation = [nextValidationDate timeIntervalSinceDate:currentTime];
  if (timeToNextValidation < 0) {
    [self.receiptValidator activateWithTrigger:[RACSignal return:currentTime]];
    return;
  }

  auto validationSignal = [[RACSignal
      interval:timeToNextValidation onScheduler:[RACScheduler scheduler]]
      take:1];

  [self.receiptValidator activateWithTrigger:validationSignal];
}

@end

NS_ASSUME_NONNULL_END
