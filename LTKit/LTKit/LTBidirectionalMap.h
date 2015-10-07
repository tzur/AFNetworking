// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Bidirectional map used to map keys to values and values to keys, with O(1) access for both
/// mappings. Therefore, to preserve a bijection, the set of mapped values cannot contain the same
/// value twice.
@interface LTBidirectionalMap<KeyType: id<NSCopying>, ObjectType> : NSObject

/// Returns an empty bidirectional map.
+ (instancetype)map;

/// Returns a bidirectional map with the given \c dictionary.
+ (instancetype)mapWithDictionary:(NSDictionary<KeyType, ObjectType> *)dictionary;

/// Designated initializer: initializes an empty bidirectional map.
- (instancetype)init;

/// Designated initializer: initializes a bidirectional map with the given \c dictionary.
- (instancetype)initWithDictionary:(NSDictionary<KeyType, ObjectType> *)dictionary;

/// Returns the object associated with the given \c key or \c nil if there's no object associated
/// with \c key.
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;

/// Sets a given \c object to be associated with the given \c key. If this value is already
/// associated with a different key, an exception will be raised.
- (void)setObject:(ObjectType)obj forKeyedSubscript:(KeyType)key;

/// Removes the given key and its associated value from the mapping.
- (void)removeObjectForKey:(KeyType)key;

/// Returns the key associated with the given \c object or \c nil if no key is associated with the
/// given \c object.
- (nullable KeyType)keyForObject:(ObjectType)object;

/// Returns an array containing all the values.
- (NSArray<ObjectType> *)allValues;

/// Number of elements in the map.
@property (readonly, nonatomic) NSUInteger count;

@end

NS_ASSUME_NONNULL_END
