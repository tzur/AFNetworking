// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "UICKeyChainStore+SecureStorage.h"

#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UICKeyChainStore (SecureStorage)

/// Error code used by \c UICKeychain when a conversion error occurs.
static const NSInteger kKeychainStoreConversionErrorCode = -67594;

/// Error code used by \c UICKeychain when an unexpected error occurs.
static const NSInteger kKeychainStoreUnexpectedErrorCode = -99999;

+ (nullable NSError *)errorForUnderlyingError:(nullable NSError *)underlyingError {
  if (!underlyingError) {
    return nil;
  }
  NSError *error;
  NSInteger errorCode;
  switch (underlyingError.code) {
    case UICKeyChainStoreErrorInvalidArguments:
      errorCode = BZRErrorCodeKeychainStorageInvalidArguments;
      break;
    case kKeychainStoreConversionErrorCode:
      errorCode = BZRErrorCodeKeychainStorageConversionFailed;
      break;
    case kKeychainStoreUnexpectedErrorCode:
      errorCode = BZRErrorCodeKeychainStorageUnexpectedFailure;
      break;
    default:
      errorCode = BZRErrorCodeKeychainStorageAccessFailed;
      break;
  }
  error = [NSError lt_errorWithCode:errorCode underlyingError:underlyingError];
  return error;
}

@end

NS_ASSUME_NONNULL_END
