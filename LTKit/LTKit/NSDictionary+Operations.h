// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Category of dictionary convenience methods for immutable usage.
@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (Operations)

/// Returns a new dictionary after merging key/value pairs from \c dictionary to a copy of the
/// receiver. If a key in \c dictionary exists in the receiver then the value from \c dictionary is
/// set to it.
- (instancetype)lt_merge:(NSDictionary<KeyType, ObjectType> *)dictionary;

/// Returns a new dictionary after removing the objects in \c keys from a copy of the receiver.
- (instancetype)lt_removeObjectsForKeys:(NSArray<KeyType> *)keys;

@end

NS_ASSUME_NONNULL_END
