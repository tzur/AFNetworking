// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "UICKeyChainStore+SecureStorage.h"

#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UICKeyChainStore (SecureStorage)

const NSInteger kUICKeychainStoreConversionErrorCode = -67594;
const NSInteger kUICKeychainStoreUnexpectedErrorCode = -99999;

+ (NSError *)errorForUnderlyingError:(NSError *)underlyingError {
  NSInteger errorCode;
  switch (underlyingError.code) {
    case UICKeyChainStoreErrorInvalidArguments:
      errorCode = BZRErrorCodeKeychainStorageInvalidArguments;
      break;
    case kUICKeychainStoreConversionErrorCode:
      errorCode = BZRErrorCodeKeychainStorageConversionFailed;
      break;
    case kUICKeychainStoreUnexpectedErrorCode:
      errorCode = BZRErrorCodeKeychainStorageUnexpectedFailure;
      break;
    default:
      errorCode = BZRErrorCodeKeychainStorageAccessFailed;
      break;
  }
  
  return [NSError lt_errorWithCode:errorCode underlyingError:underlyingError];
}

@end

NS_ASSUME_NONNULL_END
