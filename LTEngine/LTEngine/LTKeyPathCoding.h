// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <extobjc/extobjc.h>

/// Allows compile-time verification of key paths. Given a class name and a key path:
/// @code
/// @instanceKeypath(NSString, lowercaseString);
/// @endcode
#define instanceKeypath(CLASS, KEYPATH) keypath([CLASS new], KEYPATH)
