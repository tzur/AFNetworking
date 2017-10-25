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

/// Delay of the second try to fetch the receipt validation status after the first try has failed.
static const NSTimeInterval kInitialRetryDelay = 0.5;

/// Number of times to retry receipt validation status fetching.
static const NSUInteger kNumberOfRetries = 4;

@implementation BZRValidatedReceiptValidationStatusProvider

- (instancetype)initWithValidationParametersProvider:
    (id<BZRReceiptValidationParametersProvider>)validationParametersProvider {
  BZRValidatricksReceiptValidator *receiptValidator =
      [[BZRValidatricksReceiptValidator alloc] init];
  BZRRetryReceiptValidator *retryValidator =
      [[BZRRetryReceiptValidator alloc] initWithUnderlyingValidator:receiptValidator
                                                  initialRetryDelay:kInitialRetryDelay
                                                    numberOfRetries:kNumberOfRetries];
  return [self initWithReceiptValidator:retryValidator
           validationParametersProvider:validationParametersProvider];
}

- (instancetype)initWithReceiptValidator:(id<BZRReceiptValidator>)receiptValidator
    validationParametersProvider:
    (id<BZRReceiptValidationParametersProvider>)validationParametersProvider {
  if (self = [super init]) {
    _receiptValidator = receiptValidator;
    _validationParametersProvider = validationParametersProvider;
  }
  return self;
}

- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus {
  @weakify(self);
  return [[[[self receiptValidationParameters]
      tryMap:^BZRReceiptValidationParameters * _Nullable(
          BZRReceiptValidationParameters * _Nullable receiptValidationParameters, NSError **error) {
        if (!receiptValidationParameters && error) {
          *error = [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed
                                 description:@"Receipt validation parameters are nil"];
        }
        return receiptValidationParameters;
      }]
      flattenMap:^(BZRReceiptValidationParameters *receiptValidationParameters) {
        @strongify(self);
        return [self validateReceiptWithParameters:receiptValidationParameters];
      }]
      setNameWithFormat:@"%@ -fetchReceiptValidationStatus", self.description];
}

- (RACSignal<BZRReceiptValidationStatus *> *)receiptValidationParameters {
  @weakify(self);
  return [RACSignal defer:^{
    @strongify(self);
    return [RACSignal return:[self.validationParametersProvider receiptValidationParameters]];
  }];
}

- (RACSignal<BZRReceiptValidationStatus *> *)validateReceiptWithParameters:
    (BZRReceiptValidationParameters *)receiptValidationParameters {
  return [[[self.receiptValidator validateReceiptWithParameters:receiptValidationParameters]
      catch:^RACSignal *(NSError *error) {
        NSError *receiptValidationError =
            [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed underlyingError:error];
        return [RACSignal error:receiptValidationError];
      }]
      tryMap:^BZRReceiptValidationStatus * _Nullable
          (BZRReceiptValidationStatus *receiptValidationStatus, NSError **error) {
        if (!receiptValidationStatus.isValid) {
          if (error) {
            *error = [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed
                                   description:@"Failed to validate receipt, reason: %@",
                      receiptValidationStatus.error];
          }
          return nil;
        }
        return receiptValidationStatus;
      }];
}

- (RACSignal<BZREvent *> *)eventsSignal {
  return self.receiptValidator.eventsSignal;
}

@end

NS_ASSUME_NONNULL_END
