// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRKeychainStorage.h"

NS_ASSUME_NONNULL_BEGIN

/// Adds convenience method for loading a value with \c BZRKeychainStorage and verify its type.
@interface BZRKeychainStorage (TypeSafety)

/// Loads a value from storage and returns it. If there was an error while loading the value, or the
/// value loaded is not of the right class, \c nil will be returned and \c error will be set. If the
/// value doesn't exist in storage, \c nil will be returned.
- (nullable id)valueOfClass:(Class)valueClass forKey:(NSString *)key error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
