// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSError+Bazaar.h"

#import "BZRContentFetcherParameters.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kBZRErrorExceptionKey = @"BZRErrorException";
NSString * const kBZRErrorProductsRequestKey = @"BZRErrorProductsRequest";
NSString * const kBZRErrorArchivePathKey = @"BZRErrorArchivePath";
NSString * const kBZRErrorFailingItemPathKey = @"BZRErrorFailingItemPath";
NSString * const kBZRErrorTransactionKey = @"BZRErrorTransaction";
NSString * const kBZRErrorTransactionIdentifierKey = @"BZRErrorTransactionIdentifier";
NSString * const kBZRErrorProductIdentifiersKey = @"BZRErrorProductIdentifiers";
NSString * const kBZRErrorSecondsUntilSubscriptionInvalidationKey =
    @"BZRErrorSecondsUntilSubscriptionInvalidation";
NSString * const kBZRErrorLastReceiptValidationDateKey = @"BZRErrorLastReceiptValidationDate";
NSString * const kBZRErrorPurchasedProductIdentifierKey = @"BZRErrorPurchasedProductIdentifier";
NSString * const kBZRErrorContentFetcherParametersKey = @"BZRErrorContentFetcherParameters";
NSString * const kBZRErrorKeychainStorageServiceNameKey = @"BZRErrorKeychainStorageServiceName";
NSString * const kBZRErrorKeychainStorageKeyKey = @"BZRKeychainStorageKey";
NSString * const kBZRErrorKeychainStorageValueDescriptionKey =
    @"BZRKeychainStorageValueDescription";
NSString * const kBZRApplicationBundleIDKey = @"BZRApplicationBundleID";
NSString * const kBZRValidatricksErrorInfoKey = @"BZRValidatricksErrorInfo";

/// Category that adds method for getting a description of the transaction.
@interface SKPaymentTransaction (Bazaar)

/// Returns a description of the transaction with some of its proerties.
- (NSString *)bzr_description;

@end

#define BZREnumToStringMapping(enum_value) @(enum_value): @#enum_value

@implementation SKPaymentTransaction (Bazaar)

- (NSString *)bzr_description {
  static const NSDictionary<NSNumber *, NSString *> *transactionStateStringMapping = @{
    BZREnumToStringMapping(SKPaymentTransactionStatePurchasing),
    BZREnumToStringMapping(SKPaymentTransactionStatePurchased),
    BZREnumToStringMapping(SKPaymentTransactionStateFailed),
    BZREnumToStringMapping(SKPaymentTransactionStateRestored),
    BZREnumToStringMapping(SKPaymentTransactionStateDeferred)
  };

  return @{
    @keypath(self.payment, productIdentifier): self.payment.productIdentifier,
    @keypath(self, transactionDate): self.transactionDate ?: [NSNull null],
    @keypath(self, transactionIdentifier): self.transactionIdentifier ?: [NSNull null],
    @keypath(self, transactionState): transactionStateStringMapping[@(self.transactionState)],
    @keypath(self, originalTransaction): self.originalTransaction.bzr_description ? : [NSNull null]
  }.description;
}

@end

@implementation NSError (Bazaar)

+ (instancetype)bzr_errorWithCode:(NSInteger)code exception:(NSException *)exception {
  NSString *description = [NSString stringWithFormat:@"%@ exception raised, reason: %@",
                           exception.name, exception.reason];
  NSDictionary *userInfo = @{
    kBZRErrorExceptionKey: [exception copy],
    kLTErrorDescriptionKey: description
  };

  return [NSError lt_errorWithCode:code userInfo:userInfo];
}

+ (instancetype)bzr_errorWithCode:(NSInteger)code productsRequest:(SKProductsRequest *)request
                  underlyingError:(NSError *)underlyingError {
  NSDictionary *userInfo = @{
    kBZRErrorProductsRequestKey: request,
    NSUnderlyingErrorKey: underlyingError
  };
  return [NSError lt_errorWithCode:code userInfo:userInfo];
}

+ (instancetype)bzr_errorWithCode:(NSInteger)code
                      archivePath:(NSString *)archivePath
           failingArchiveItemPath:(nullable NSString *)failingItemPath
                  underlyingError:(nullable NSError *)underlyingError
                      description:(nullable NSString *)description {
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
  userInfo[kBZRErrorArchivePathKey] = archivePath;
  if (failingItemPath) {
    userInfo[kBZRErrorFailingItemPathKey] = [failingItemPath copy];
  }
  if (underlyingError) {
    userInfo[NSUnderlyingErrorKey] = [underlyingError copy];
  }
  if (description) {
    userInfo[kLTErrorDescriptionKey] = [description copy];
  }

  return [NSError lt_errorWithCode:code userInfo:userInfo];
}

+ (instancetype)bzr_errorWithCode:(NSInteger)code
                      transaction:(SKPaymentTransaction *)transaction {
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
  userInfo[kBZRErrorTransactionKey] = transaction;
  userInfo[kBZRErrorTransactionIdentifierKey] = transaction.transactionIdentifier;
  userInfo[kLTErrorDescriptionKey] = transaction.bzr_description;
  if (transaction.transactionState == SKPaymentTransactionStateFailed) {
    userInfo[NSUnderlyingErrorKey] = transaction.error;
  }
  return [NSError lt_errorWithCode:code userInfo:userInfo];
}

+ (instancetype)bzr_invalidProductsErrorWithIdentifiers:(NSSet<NSString *> *)productIdentifiers {
  NSDictionary *userInfo = @{
    kBZRErrorProductIdentifiersKey: [productIdentifiers copy]
  };
  return [self lt_errorWithCode:BZRErrorCodeInvalidProductIdentifier userInfo:userInfo];
}

+ (instancetype)bzr_errorWithSecondsUntilSubscriptionInvalidation:
    (NSNumber *)secondsUntilSubscriptionInvalidation
    lastReceiptValidationDate:(NSDate *)lastReceiptValidationDate
    underlyingError:(NSError *)underlyingError {
  NSDictionary *userInfo = @{
    kBZRErrorSecondsUntilSubscriptionInvalidationKey: secondsUntilSubscriptionInvalidation,
    kBZRErrorLastReceiptValidationDateKey: lastReceiptValidationDate,
    NSUnderlyingErrorKey: underlyingError
  };
  return [NSError lt_errorWithCode:BZRErrorCodePeriodicReceiptValidationFailed userInfo:userInfo];
}

+ (instancetype)bzr_purchasedProductNotFoundInReceipt:(NSString *)productIdentifier {
  NSDictionary *userInfo = @{
    kBZRErrorPurchasedProductIdentifierKey: [productIdentifier copy]
  };
  return [self lt_errorWithCode:BZRErrorCodeTransactionNotFoundInReceipt userInfo:userInfo];
}

+ (instancetype)bzr_errorWithContentFetcherParameters:(BZRContentFetcherParameters *)parameters
                                      underlyingError:(NSError *)underlyingError {
  NSDictionary *userInfo = @{
    kBZRErrorContentFetcherParametersKey: parameters,
    NSUnderlyingErrorKey: underlyingError
  };
  return [self lt_errorWithCode:BZRErrorCodeFetchingProductContentFailed userInfo:userInfo];
}

+ (instancetype)bzr_storageErrorWithCode:(NSInteger)code
                         underlyingError:(nullable NSError *)underlyingError
                             description:(NSString *)description
              keychainStorageServiceName:(nullable NSString *)keychainStorageServiceName
                      keychainStorageKey:(NSString *)keychainStorageKey
                    keychainStorageValue:(nullable id<NSSecureCoding>)keychainStorageValue {
  auto underlyingErrorDictionary = underlyingError ? @{NSUnderlyingErrorKey: underlyingError} : @{};
  auto serviceNameDictionary = keychainStorageServiceName ?
      @{kBZRErrorKeychainStorageServiceNameKey: [keychainStorageServiceName copy]} : @{};
  auto _Nullable valueDescription = ((NSObject *)keychainStorageValue).description;
  auto valueDictionary = valueDescription ?
      @{kBZRErrorKeychainStorageValueDescriptionKey: valueDescription} : @{};

  NSDictionary *userInfo = [[[@{
    kLTErrorDescriptionKey: description,
    kBZRErrorKeychainStorageKeyKey: keychainStorageKey
  }
  mtl_dictionaryByAddingEntriesFromDictionary:underlyingErrorDictionary]
  mtl_dictionaryByAddingEntriesFromDictionary:serviceNameDictionary]
  mtl_dictionaryByAddingEntriesFromDictionary:valueDictionary];
  return [self lt_errorWithCode:code userInfo:userInfo];
}

+ (instancetype)bzr_validatricksRequestErrorWithURL:(NSURL *)url
                              validatricksErrorInfo:(BZRValidatricksErrorInfo *)errorInfo
                                    underlyingError:(NSError *)underlyingError {
  return [self lt_errorWithCode:BZRErrorCodeValidatricksRequestFailed userInfo:@{
    NSURLErrorKey: url,
    kBZRValidatricksErrorInfoKey: errorInfo,
    NSUnderlyingErrorKey: underlyingError
  }];
}

- (nullable NSException *)bzr_exception {
  return self.userInfo[kBZRErrorExceptionKey];
}

- (nullable SKProductsRequest *)bzr_productsRequest {
  return self.userInfo[kBZRErrorProductsRequestKey];
}

- (nullable NSString *)bzr_archivePath {
  return self.userInfo[kBZRErrorArchivePathKey];
}

- (nullable NSString *)bzr_failingItemPath {
  return self.userInfo[kBZRErrorFailingItemPathKey];
}

- (nullable SKPaymentTransaction *)bzr_transaction {
  return self.userInfo[kBZRErrorTransactionKey];
}

- (nullable SKPaymentTransaction *)bzr_transactionIdentifier {
  return self.userInfo[kBZRErrorTransactionIdentifierKey];
}

- (nullable NSSet<NSString *> *)bzr_productIdentifiers {
  return self.userInfo[kBZRErrorProductIdentifiersKey];
}

- (nullable NSNumber *)bzr_secondsUntilSubscriptionInvalidation {
  return self.userInfo[kBZRErrorSecondsUntilSubscriptionInvalidationKey];
}

- (nullable NSDate *)bzr_lastReceiptValidationDate {
  return self.userInfo[kBZRErrorLastReceiptValidationDateKey];
}

- (nullable NSString *)bzr_purchasedProductIdentifier {
  return self.userInfo[kBZRErrorPurchasedProductIdentifierKey];
}

- (nullable NSString *)bzr_contentFetcherParameters {
  return self.userInfo[kBZRErrorContentFetcherParametersKey];
}

- (nullable NSString *)bzr_keychainStorageServiceName {
  return self.userInfo[kBZRErrorKeychainStorageServiceNameKey];
}

- (nullable NSString *)bzr_keychainStorageKey {
  return self.userInfo[kBZRErrorKeychainStorageKeyKey];
}

- (nullable NSString *)bzr_keychainStorageValueDescription {
  return self.userInfo[kBZRErrorKeychainStorageValueDescriptionKey];
}

- (nullable NSString *)bzr_applicationBundleID {
  return self.userInfo[kBZRApplicationBundleIDKey];
}

- (nullable BZRValidatricksErrorInfo *)bzr_validatricksErrorInfo {
  return self.userInfo[kBZRValidatricksErrorInfoKey];
}

@end

NS_ASSUME_NONNULL_END
