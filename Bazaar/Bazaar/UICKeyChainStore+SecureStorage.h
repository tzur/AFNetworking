// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import <UICKeyChainStore/UICKeyChainStore.h>

#import "BZRKeychainHandler.h"

NS_ASSUME_NONNULL_BEGIN

/// Error code used by \c UICKeychain when a conversion error occurs.
extern const NSInteger kUICKeychainStoreConversionErrorCode;

/// Error code used by \c UICKeychain when an unexpected error occurs.
extern const NSInteger kUICKeychainStoreUnexpectedErrorCode;

/// Category for conforming to \c BZRKeychainHandler.
@interface UICKeyChainStore (SecureStorage) <BZRKeychainHandler>
@end

NS_ASSUME_NONNULL_END
