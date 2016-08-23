// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationStatusProvider.h"

#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidator.h"
#import "BZRValidatricksReceiptValidator.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRReceiptValidationStatusProvider ()

/// Storage used to store and load \c receiptValidationStatus
@property (readonly, nonatomic) BZRKeychainStorage *keychainStorage;

/// Validator used to validate the receipt and receive \c receiptValidationStatus.
@property (readonly, nonatomic) id<BZRReceiptValidator> receiptValidator;

/// Provider that provides parameters to the \c receiptValidator.
@property (readonly, nonatomic) id<BZRReceiptValidationParametersProvider>
    validationParametersProvider;

/// Latest \c BZRReceiptValidationStatus validated successfully with \c receiptValidator.
@property (nonatomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

/// Stores the latest storage error that occurred.
@property (strong, nonatomic, nullable) NSError *storageError;

@end

@implementation BZRReceiptValidationStatusProvider

@synthesize receiptValidationStatus = _receiptValidationStatus;

/// Key to the \c receiptValidationStatus stored in the secure storage.
NSString * const kValidationStatusStorageKey = @"validationStatus";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage {
  id<BZRReceiptValidator> receiptValidator = [[BZRValidatricksReceiptValidator alloc] init];
  BZRReceiptValidationParametersProvider *validationParametersProvider =
      [[BZRReceiptValidationParametersProvider alloc] init];

  return [self initWithKeychainStorage:keychainStorage receiptValidator:receiptValidator
          validationParametersProvider:validationParametersProvider];
}

- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage
    receiptValidator:(id<BZRReceiptValidator>)receiptValidator
    validationParametersProvider:
    (id<BZRReceiptValidationParametersProvider>)validationParametersProvider {
  if (self = [super init]) {
    _receiptValidator = receiptValidator;
    _keychainStorage = keychainStorage;
    _validationParametersProvider = validationParametersProvider;
    _storageErrorsSignal = RACObserve(self, storageError);
  }
  return self;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  if (!_receiptValidationStatus) {
    _receiptValidationStatus = [self loadValidationStatusFromStorage];
  }
  return _receiptValidationStatus;
}

- (nullable BZRReceiptValidationStatus *)loadValidationStatusFromStorage {
  NSError *error;
  BZRReceiptValidationStatus *receiptValidationStatus =
      [self.keychainStorage valueOfClass:[BZRReceiptValidationStatus class]
                                  forKey:kValidationStatusStorageKey error:&error];
  if (error) {
    self.storageError = error;
    return nil;
  }
  return receiptValidationStatus;
}

- (void)setReceiptValidationStatus:(nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  _receiptValidationStatus = receiptValidationStatus;
  NSError *error;
  [self.keychainStorage setValue:receiptValidationStatus forKey:kValidationStatusStorageKey
                           error:&error];
  if (error) {
    self.storageError =
        [NSError lt_errorWithCode:BZRErrorCodeStoringDataToStorageFailed underlyingError:error];
  }
}

#pragma mark -
#pragma mark Validating receipt
#pragma mark -

- (RACSignal *)validateReceipt {
  @weakify(self);
  return [[[[RACSignal defer:^RACSignal *{
    return [RACSignal return:[self.validationParametersProvider receiptValidationParameters]];
  }] tryMap:^BZRReceiptValidationParameters * _Nullable
            (BZRReceiptValidationParameters * _Nullable receiptValidationParameters,
             NSError **error) {
    if (!receiptValidationParameters) {
      NSString *description = @"Receipt validation parameters are nil";
      *error = [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed
                             description:description];
      return nil;
    }
    return receiptValidationParameters;
  }] flattenMap:^RACStream *(BZRReceiptValidationParameters *receiptValidationParameters) {
    @strongify(self);
    return [self validateReceiptWithParameters:receiptValidationParameters];
  }] setNameWithFormat:@"%@ -validateReceipt", self.description];
}

- (RACSignal *)validateReceiptWithParameters:
    (BZRReceiptValidationParameters *)receiptValidationParameters {
  return [[[self.receiptValidator validateReceiptWithParameters:receiptValidationParameters]
      tryMap:^BZRReceiptValidationStatus * _Nullable
          (BZRReceiptValidationStatus *receiptValidationStatus, NSError **error) {
        if (!receiptValidationStatus.isValid) {
          NSString *description = [NSString stringWithFormat:@"Failed to validate receipt, "
                                   "reason: %@", receiptValidationStatus.error];
          *error = [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed
                                 description:description];
          return nil;
        }
        return receiptValidationStatus;
      }] doNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
        self.receiptValidationStatus = receiptValidationStatus;
      }];
}

@end

NS_ASSUME_NONNULL_END
