// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "UICKeyChainStore+SecureStorage.h"

#import <Security/SecBase.h>

#import "NSErrorCodes+Bazaar.h"

/// Error code used by \c UICKeyChainStore when a conversion error occurs.
static const NSInteger kKeychainStoreConversionErrorCode = -67594;

/// Error code used by \c UICKeyChainStore when an unexpected error occurs.
static const NSInteger kKeychainStoreUnexpectedErrorCode = -99999;

SpecBegin(UICKeyChainStoreSecureStorage)

context(@"underlying error", ^{
  it(@"should convert unexpected error correctly", ^{
    NSError *underlyingError = [NSError lt_errorWithCode:kKeychainStoreUnexpectedErrorCode];
    NSError *error = [UICKeyChainStore errorForUnderlyingError:underlyingError];
    expect(error.lt_underlyingError).to.equal(underlyingError);
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(BZRErrorCodeKeychainStorageUnexpectedFailure);
  });
  
  it(@"should convert conversion error correctly", ^{
    NSError *underlyingError = [NSError lt_errorWithCode:kKeychainStoreConversionErrorCode];
    NSError *error = [UICKeyChainStore errorForUnderlyingError:underlyingError];
    expect(error.lt_underlyingError).to.equal(underlyingError);
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(BZRErrorCodeKeychainStorageConversionFailed);
  });
  
  it(@"should convert access error correctly", ^{
    NSError *underlyingError = [NSError lt_errorWithCode:errSecInteractionNotAllowed];
    NSError *error = [UICKeyChainStore errorForUnderlyingError:underlyingError];
    expect(error.lt_underlyingError).to.equal(underlyingError);
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(BZRErrorCodeKeychainStorageAccessFailed);
  });
  
  it(@"should convert invalid arguments error correctly", ^{
    NSError *underlyingError = [NSError lt_errorWithCode:UICKeyChainStoreErrorInvalidArguments];
    NSError *error = [UICKeyChainStore errorForUnderlyingError:underlyingError];
    expect(error.lt_underlyingError).to.equal(underlyingError);
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(BZRErrorCodeKeychainStorageInvalidArguments);
  });
});

SpecEnd
