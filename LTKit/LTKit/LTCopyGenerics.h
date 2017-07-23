// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Yaron Inger.

// This file overrides the NSObject declaration of copy with specialized ones that retain the
// generic type. This is pure compiler sugar and will create additional warnings for type
// mismatches.
//
// @note id-casted objects will create a warning when copy is called on them as there are multiple
// declarations available. Either cast to specific type or to \c NSObject to work around this.

@interface NSArray<__covariant ObjectType> (LTCopyGenerics)

/// Same as \c copy but retains the generic type.
- (NSArray<ObjectType> *)copy;

/// Same as \c mutableCopy but retains the generic type.
- (NSMutableArray<ObjectType> *)mutableCopy;

@end

@interface NSSet<__covariant ObjectType> (LTCopyGenerics)

/// Same as \c copy but retains the generic type.
- (NSSet<ObjectType> *)copy;

/// Same as \c mutableCopy but retains the generic type.
- (NSMutableSet<ObjectType> *)mutableCopy;

@end

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (LTCopyGenerics)

/// Same as \c copy but retains the generic type.
- (NSDictionary<KeyType, ObjectType> *)copy;

/// Same as \c mutableCopy but retains the generic type.
- (NSMutableDictionary<KeyType, ObjectType> *)mutableCopy;

@end

@interface NSOrderedSet<__covariant ObjectType> (LTCopyGenerics)

/// Same as \c copy but retains the generic type.
- (NSOrderedSet<ObjectType> *)copy;

/// Same as \c mutableCopy but retains the generic type.
- (NSMutableOrderedSet<ObjectType> *)mutableCopy;

@end

@interface NSHashTable<ObjectType> (LTCopyGenerics)

/// Same as \c copy but retains the generic type.
- (NSHashTable<ObjectType> *)copy;

@end

@interface NSMapTable<KeyType, ObjectType> (LTCopyGenerics)

/// Same as \c copy but retains the generic type.
- (NSMapTable<KeyType, ObjectType> *)copy;

@end
