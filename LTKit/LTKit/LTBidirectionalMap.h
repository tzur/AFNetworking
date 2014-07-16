// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Bidirectional map used to map keys to values and values to keys, with O(1) access for both
/// mappings. Therefore, to preserve a bijection, the set of mapped values cannot contain the same
/// value twice.
@interface LTBidirectionalMap : NSObject

/// Returns an empty bidirectional map.
+ (instancetype)map;

/// Returns a bidirectional map with the given \c dictionary.
+ (instancetype)mapWithDictionary:(NSDictionary *)dictionary;

/// Designated initializer: initializes an empty bidirectional map.
- (instancetype)init;

/// Designated initializer: initializes a bidirectional map with the given \c dictionary.
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/// Returns the object associated with the given \c key.
- (id)objectForKeyedSubscript:(id<NSCopying>)key;

/// Sets a given \c object to be associated with the given \c key. If this value is already
/// associated with a different key, an exception will be raised.
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key;

/// Removes the given key and its associated value from the mapping.
- (void)removeObjectForKey:(id<NSCopying>)key;

/// Returns the key associated with the given \c object.
- (id)keyForObject:(id)object;

/// Returns an array containing all the values.
- (NSArray *)allValues;

/// Number of elements in the map.
@property (readonly, nonatomic) NSUInteger count;

@end
