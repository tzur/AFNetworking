// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRRetryReceiptValidator.h"

#import "BZREvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRRetryReceiptValidator ()

/// Validator used to validate the receipt.
@property (readonly, nonatomic) id<BZRReceiptValidator> underlyingValidator;

/// Specifying the delay between the first and second validation tries.
@property (nonatomic) NSTimeInterval initialRetryDelay;

/// Specifies the number of validation tries after the first try.
@property (nonatomic) NSUInteger numberOfRetries;

/// Subject used to send receipt validation errors.
@property (readonly, nonatomic) RACSubject<NSError *> *validationErrorsSubject;

@end

@implementation BZRRetryReceiptValidator

- (instancetype)initWithUnderlyingValidator:(id<BZRReceiptValidator>)underlyingValidator
                          initialRetryDelay:(NSTimeInterval)initialRetryDelay
                            numberOfRetries:(NSUInteger)numberOfRetries {
  if (self = [super init]) {
    _underlyingValidator = underlyingValidator;
    _initialRetryDelay = initialRetryDelay;
    _numberOfRetries = numberOfRetries;
    _validationErrorsSubject = [RACSubject subject];
  }
  return self;
}

#pragma mark -
#pragma mark BZRReceiptValidator
#pragma mark -

- (RACSignal<BZRReceiptValidationStatus *> *)
    validateReceiptWithParameters:(BZRReceiptValidationParameters *)parameters {
  if (!self.numberOfRetries) {
    return [self.underlyingValidator validateReceiptWithParameters:parameters];
  }

  __block NSTimeInterval secondsUntilNextRetry = self.initialRetryDelay;

  @weakify(self);
  return [[[[RACSignal defer:^{
        @strongify(self);
        return [self.underlyingValidator validateReceiptWithParameters:parameters];
      }]
      doError:^(NSError *error) {
        @strongify(self);
        [self.validationErrorsSubject sendNext:error];
      }]
      catch:^(NSError *error) {
        RACSignal *delaySignal = [[[RACSignal empty]
            delay:secondsUntilNextRetry]
            concat:[RACSignal error:error]];
        secondsUntilNextRetry *= 2;
        return delaySignal;
      }]
      retry:self.numberOfRetries];
}

- (RACSignal<BZREvent *> *)eventsSignal {
  return [[[self.validationErrorsSubject
      map:^BZREvent *(NSError *error) {
        return [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error];
      }]
      merge:self.underlyingValidator.eventsSignal]
      takeUntil:self.rac_willDeallocSignal];
}

@end

NS_ASSUME_NONNULL_END
