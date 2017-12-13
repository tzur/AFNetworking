// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRValidatedReceiptValidationStatusProvider.h"

#import "BZRReceiptDataCache.h"
#import "BZRReceiptValidationError.h"
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

/// Cache used to store receipt data when validation is requested and receipt data is valid.
@property (readonly, nonatomic) BZRReceiptDataCache *receiptDataCache;

/// Current application's bundle ID, used to cache receipt data to the storage of the current
/// application
@property (readonly, nonatomic) NSString *currentApplicationBundleID;

@end

/// Delay of the second try to fetch the receipt validation status after the first try has failed.
static const NSTimeInterval kInitialRetryDelay = 0.5;

/// Number of times to retry receipt validation status fetching.
static const NSUInteger kNumberOfRetries = 4;

@implementation BZRValidatedReceiptValidationStatusProvider

- (instancetype)initWithValidationParametersProvider:
    (id<BZRReceiptValidationParametersProvider>)validationParametersProvider
    receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
    currentApplicationBundleID:(NSString *)currentApplicationBundleID {
  BZRValidatricksReceiptValidator *receiptValidator =
      [[BZRValidatricksReceiptValidator alloc] init];
  BZRRetryReceiptValidator *retryValidator =
      [[BZRRetryReceiptValidator alloc] initWithUnderlyingValidator:receiptValidator
                                                  initialRetryDelay:kInitialRetryDelay
                                                    numberOfRetries:kNumberOfRetries];
  return [self initWithReceiptValidator:retryValidator
           validationParametersProvider:validationParametersProvider
                       receiptDataCache:receiptDataCache
             currentApplicationBundleID:currentApplicationBundleID];
}

- (instancetype)initWithReceiptValidator:(id<BZRReceiptValidator>)receiptValidator
    validationParametersProvider:
    (id<BZRReceiptValidationParametersProvider>)validationParametersProvider
    receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
    currentApplicationBundleID:(NSString *)currentApplicationBundleID {
  if (self = [super init]) {
    _receiptValidator = receiptValidator;
    _receiptDataCache = receiptDataCache;
    _validationParametersProvider = validationParametersProvider;
    _currentApplicationBundleID = [currentApplicationBundleID copy];
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

    return [RACSignal return:
            [self.validationParametersProvider receiptValidationParametersForApplication:
             self.currentApplicationBundleID]];
  }];
}

- (RACSignal<BZRReceiptValidationStatus *> *)validateReceiptWithParameters:
    (BZRReceiptValidationParameters *)receiptValidationParameters {
  return [[[[self.receiptValidator validateReceiptWithParameters:receiptValidationParameters]
      catch:^RACSignal *(NSError *error) {
        NSError *receiptValidationError =
            [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed underlyingError:error];
        return [RACSignal error:receiptValidationError];
      }]
      doNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
        [self saveReceiptDataToStorageIfValid:receiptValidationParameters.receiptData
                      receiptValidationStatus:receiptValidationStatus];
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

- (void)saveReceiptDataToStorageIfValid:(nullable NSData *)receiptData
                receiptValidationStatus:(BZRReceiptValidationStatus *)receiptValidationStatus {
  // The receipt is not saved to storage if it is \c nil or an error related to the receipt has
  // returned from validation.
  if (!receiptData || (receiptValidationStatus.error &&
       ![receiptValidationStatus.error isEqual:$(BZRReceiptValidationErrorServerIsNotAvailable)] &&
       ![receiptValidationStatus.error isEqual:$(BZRReceiptValidationErrorUnknown)])) {
    return;
  }

  [self.receiptDataCache storeReceiptData:receiptData
                      applicationBundleID:self.currentApplicationBundleID error:nil];
}

- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus:
    (NSString __unused *)applicationBundleID {
  return [self fetchReceiptValidationStatus];
}

- (RACSignal<BZREvent *> *)eventsSignal {
  return self.receiptValidator.eventsSignal;
}

@end

NS_ASSUME_NONNULL_END
