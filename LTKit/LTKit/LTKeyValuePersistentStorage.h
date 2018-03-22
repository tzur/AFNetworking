// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Objects conforming to this protocol persistently store plist compatible objects. Implementers of
/// this protocol guarantee it to be thread-safe.
@protocol LTKeyValuePersistentStorage <NSObject>

/// Sets \c value to key \c key. If \c value is \c nil then the key is removed from the receiver.
///
/// @attention \c value must be a plist compatible object, otherwise an
/// \c NSInvalidArgumentException is raised.
- (void)setObject:(nullable id)value forKey:(NSString *)key;

/// Removes the object stored with the given \c key.
///
/// @note is equivalent to <tt>[self setObject:nil forKey:key]</tt>.
- (void)removeObjectForKey:(NSString *)key;

/// Returns a stored object for \c key. Returns \c nil if no object exists for \c key.
- (nullable id)objectForKey:(NSString *)key;

@end

/// Conforms \c NSUserDefaults to \c LTKeyValuePersistentStorage
@interface NSUserDefaults (LTKeyValuePersistentStorage) <LTKeyValuePersistentStorage>
@end

NS_ASSUME_NONNULL_END
