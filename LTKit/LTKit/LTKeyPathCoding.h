// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <extobjc/EXTKeyPathCoding.h>

NS_ASSUME_NONNULL_BEGIN

/// Allows compile-time verification of key paths. Given a class name and a key path:
/// @code
/// @instanceKeypath(NSString, lowercaseString);
/// @endcode
#define instanceKeypath(CLASS, KEYPATH) keypath([CLASS new], KEYPATH)

NS_ASSUME_NONNULL_END
