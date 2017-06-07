// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

/// Objects conforming to this protocol store plist compatible objects.
@protocol LABStorage <NSObject>

/// Sets \c value to key \c key. If \c values is \c nil then the key is removed from the receiver.
///
/// @attention \c value must be a plist compatible object, otherwise an
/// \c NSInvalidArgumentException is raised.
- (void)setObject:(nullable id)value forKey:(NSString *)key;

/// Returns a stored object for \c key. Returns \c nil if no object exists for \c key.
- (nullable id)objectForKey:(NSString *)key;

@end

/// Conforms \c NSUserDefaults to \c LABStorage.
@interface NSUserDefaults (Storage) <LABStorage>
@end

NS_ASSUME_NONNULL_END
