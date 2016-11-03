// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRValidatedReceiptValidationStatusProvider.h"

#import "BZRReceiptValidationParameters.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidator.h"
#import "BZRRetryReceiptValidator.h"
#import "BZRValidatricksReceiptValidator.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRValidatedReceiptValidationStatusProvider ()

/// Validator used to validate the receipt and receive \c receiptValidationStatus.
@property (readonly, nonatomic) id<BZRReceiptValidator> receiptValidator;

/// Provider that provides parameters to the \c receiptValidator.
@property (readonly, nonatomic) id<BZRReceiptValidationParametersProvider>
    validationParametersProvider;

@end

@implementation BZRValidatedReceiptValidationStatusProvider

@synthesize nonCriticalErrorsSignal = _nonCriticalErrorsSignal;

- (instancetype)init {
  NSTimeInterval kInitialRetryDelay = 0.5;
  NSUInteger kNumberOfRetries = 3;

  BZRValidatricksReceiptValidator *receiptValidator =
      [[BZRValidatricksReceiptValidator alloc] init];
  BZRRetryReceiptValidator *retryValidator =
      [[BZRRetryReceiptValidator alloc] initWithUnderlyingValidator:receiptValidator
                                                  initialRetryDelay:kInitialRetryDelay
                                                    numberOfRetries:kNumberOfRetries];
  BZRReceiptValidationParametersProvider *validationParametersProvider =
      [[BZRReceiptValidationParametersProvider alloc] init];
  return [self initWithReceiptValidator:retryValidator
           validationParametersProvider:validationParametersProvider];
}

- (instancetype)initWithReceiptValidator:(id<BZRReceiptValidator>)receiptValidator
    validationParametersProvider:
    (id<BZRReceiptValidationParametersProvider>)validationParametersProvider {
  if (self = [super init]) {
    _receiptValidator = receiptValidator;
    _validationParametersProvider = validationParametersProvider;
    _nonCriticalErrorsSignal = [[RACSignal never] takeUntil:[self rac_willDeallocSignal]];
  }
  return self;
}

- (RACSignal *)fetchReceiptValidationStatus {
  @weakify(self);
  return [[[[self receiptValidationParameters]
      tryMap:^BZRReceiptValidationParameters * _Nullable(
          BZRReceiptValidationParameters * _Nullable receiptValidationParameters, NSError **error) {
        if (!receiptValidationParameters && error) {
          NSString *description = @"Receipt validation parameters are nil";
          *error = [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed
                                 description:description];
        }
        return receiptValidationParameters;
      }]
      flattenMap:^RACStream *(BZRReceiptValidationParameters *receiptValidationParameters) {
        @strongify(self);
        return [self validateReceiptWithParameters:receiptValidationParameters];
      }]
      setNameWithFormat:@"%@ -fetchReceiptValidationStatus", self.description];
}

- (RACSignal *)receiptValidationParameters {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    return [RACSignal return:[self.validationParametersProvider receiptValidationParameters]];
  }];
}

- (RACSignal *)validateReceiptWithParameters:
    (BZRReceiptValidationParameters *)receiptValidationParameters {
  return [[self.receiptValidator validateReceiptWithParameters:receiptValidationParameters]
      tryMap:^BZRReceiptValidationStatus * _Nullable
          (BZRReceiptValidationStatus *receiptValidationStatus, NSError **error) {
        if (!receiptValidationStatus.isValid) {
          if (error) {
            NSString *description = [NSString stringWithFormat:@"Failed to validate receipt, "
                                     "reason: %@", receiptValidationStatus.error];
            *error = [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed
                                   description:description];
          }
          return nil;
        }
        return receiptValidationStatus;
      }];
}

@end

NS_ASSUME_NONNULL_END
