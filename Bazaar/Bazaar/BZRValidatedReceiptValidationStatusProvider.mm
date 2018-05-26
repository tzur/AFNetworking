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
#import "BZRUserIDProvider.h"
#import "BZRValidatricksReceiptValidator.h"
#import "NSError+Bazaar.h"
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

/// Provider used to provide a unique identifier of the user.
@property (readonly, nonatomic) id<BZRUserIDProvider> userIDProvider;

@end

/// Delay of the second try to fetch the receipt validation status after the first try has failed.
static const NSTimeInterval kInitialRetryDelay = 0.5;

/// Number of times to retry receipt validation status fetching.
static const NSUInteger kNumberOfRetries = 4;

@implementation BZRValidatedReceiptValidationStatusProvider

- (instancetype)initWithValidationParametersProvider:
    (id<BZRReceiptValidationParametersProvider>)validationParametersProvider
    receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
    userIDProvider:(id<BZRUserIDProvider>)userIDProvider {
  BZRValidatricksReceiptValidator *receiptValidator =
      [[BZRValidatricksReceiptValidator alloc] init];
  BZRRetryReceiptValidator *retryValidator =
      [[BZRRetryReceiptValidator alloc] initWithUnderlyingValidator:receiptValidator
                                                  initialRetryDelay:kInitialRetryDelay
                                                    numberOfRetries:kNumberOfRetries];
  return [self initWithReceiptValidator:retryValidator
           validationParametersProvider:validationParametersProvider
                       receiptDataCache:receiptDataCache
                         userIDProvider:userIDProvider];
}

- (instancetype)initWithReceiptValidator:(id<BZRReceiptValidator>)receiptValidator
    validationParametersProvider:
    (id<BZRReceiptValidationParametersProvider>)validationParametersProvider
    receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
    userIDProvider:(id<BZRUserIDProvider>)userIDProvider {
  if (self = [super init]) {
    _receiptValidator = receiptValidator;
    _receiptDataCache = receiptDataCache;
    _validationParametersProvider = validationParametersProvider;
    _userIDProvider = userIDProvider;
  }
  return self;
}

- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus:
    (NSString *)applicationBundleID {
  @weakify(self);
  return [[[[[self receiptValidationParameters:applicationBundleID]
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
        return [self validateReceiptWithApplicationBundleID:applicationBundleID
                                receiptValidationParameters:receiptValidationParameters];
      }]
      catch:^RACSignal *(NSError *error) {
        auto userInfoWithBundleID = [error.userInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
          kBZRApplicationBundleIDKey: applicationBundleID
        }];
        auto errorWithBundleID = [NSError lt_errorWithCode:error.code
                                                  userInfo:userInfoWithBundleID];
        return [RACSignal error:errorWithBundleID];
      }]
      setNameWithFormat:@"%@ -fetchReceiptValidationStatus", self.description];
}

- (RACSignal<BZRReceiptValidationStatus *> *)receiptValidationParameters:
    (NSString *)applicationBundleID {
  @weakify(self);
  return [RACSignal defer:^{
    @strongify(self);

    return [RACSignal return:
            [self.validationParametersProvider receiptValidationParametersForApplication:
             applicationBundleID userID:self.userIDProvider.userID]];
  }];
}

- (RACSignal<BZRReceiptValidationStatus *> *)validateReceiptWithApplicationBundleID:
    (NSString *)applicationBundleID receiptValidationParameters:
    (BZRReceiptValidationParameters *)receiptValidationParameters {
  return [[[[self.receiptValidator validateReceiptWithParameters:receiptValidationParameters]
      catch:^RACSignal *(NSError *error) {
        NSError *receiptValidationError =
            [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed underlyingError:error];
        return [RACSignal error:receiptValidationError];
      }]
      doNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
        [self saveReceiptDataToStorageIfValid:receiptValidationParameters.receiptData
                      receiptValidationStatus:receiptValidationStatus
                          applicationBundleID:applicationBundleID];
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
                receiptValidationStatus:(BZRReceiptValidationStatus *)receiptValidationStatus
                    applicationBundleID:(NSString *)applicationBundleID {
  // The receipt is not saved to storage if it is \c nil or an error related to the receipt has
  // returned from validation.
  if (!receiptData || (receiptValidationStatus.error &&
      ![receiptValidationStatus.error isEqual:$(BZRReceiptValidationErrorUnknown)])) {
    return;
  }

  [self.receiptDataCache storeReceiptData:receiptData applicationBundleID:applicationBundleID
                                    error:nil];
}

- (RACSignal<BZREvent *> *)eventsSignal {
  return self.receiptValidator.eventsSignal;
}

@end

NS_ASSUME_NONNULL_END
