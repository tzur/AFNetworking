// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kBZRErrorExceptionKey = @"BZRErrorException";
NSString * const kBZRErrorProductsRequestKey = @"BZRErrorProductsRequest";
NSString * const kBZRErrorArchivePathKey = @"BZRErrorArchivePath";
NSString * const kBZRErrorFailingItemPathKey = @"BZRErrorFailingItemPath";
NSString * const kBZRErrorTransactionKey = @"BZRErrorTransaction";
NSString * const kBZRErrorProductIdentifiersKey = @"BZRErrorProductIdentifiers";

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
  if (transaction.transactionState == SKPaymentTransactionStateFailed) {
    userInfo[NSUnderlyingErrorKey] = transaction.error;
  }
  return [NSError lt_errorWithCode:code userInfo:userInfo];
}

+ (instancetype)bzr_invalidProductsErrorWithIdentifers:(NSSet<NSString *> *)productIdentifiers {
  NSDictionary *userInfo = @{
    kBZRErrorProductIdentifiersKey: [productIdentifiers copy]
  };
  return [self lt_errorWithCode:BZRErrorCodeInvalidProductIdentifer userInfo:userInfo];
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

- (nullable NSSet<NSString *> *)bzr_productIdentifiers {
  return self.userInfo[kBZRErrorProductIdentifiersKey];
}

@end

NS_ASSUME_NONNULL_END
