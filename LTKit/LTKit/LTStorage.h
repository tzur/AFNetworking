// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Objects conforming to this protocol store plist compatible objects.
@protocol LTStorage <NSObject>

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

/// Waits for any pending asynchronous updates to the storage and returns. Returns \c YES if the
/// data was saved successfully to disk, otherwise \c NO.
- (BOOL)synchronize;

@end

/// Conforms \c NSUserDefaults to \c LTStorage
@interface NSUserDefaults (LTStorage) <LTStorage>
@end

NS_ASSUME_NONNULL_END
