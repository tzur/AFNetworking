// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import <UICKeyChainStore/UICKeyChainStore.h>

#import "BZRKeyChainHandler.h"

NS_ASSUME_NONNULL_BEGIN

/// Category for conforming to \c BZRKeychainHandler.
@interface UICKeyChainStore (SecureStorage) <BZRKeychainHandler>
@end

NS_ASSUME_NONNULL_END
