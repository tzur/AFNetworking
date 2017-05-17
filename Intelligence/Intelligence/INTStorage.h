// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Objects conforming to this protocol store plist compatible objects.
@protocol INTStorage <NSObject>

/// Sets \c value to key \c key. if \c values is \c nil then the key is removed from the receiver.
///
/// @attention \c value must be a plist compatible object, otherwise a \c NSInvalidArgumentException
/// is raised.
- (void)setObject:(nullable id)value forKey:(NSString *)key;

/// Returns a stored object for \c key. Returns \c nil if no object exists for \c key.
- (nullable id)objectForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
