// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Fast enumerator that wraps a \c source enumeration and supports basic functional operators such
/// as map, flatMap and flatten. The operators are lazy and do not execute the operators until they
/// are required to by enumeration.
///
/// @note the source enumeration is referenced by this enumerator, but the enumerator is not
/// considered as an owner of the source. Therefore, it is not copied and it can be changed after
/// the enumerator has been created.
@interface BLUFastEnumerator : NSObject <NSCopying, NSFastEnumeration>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new enumerator with the given \c source. The enumerator holds a reference to the
/// source, but it is not being copied. Additional changes in the \c source after the enumerator's
/// initialization will be reflected on the enumerator as well.
- (instancetype)initWithSource:(id<NSFastEnumeration>)source;

/// Block that maps a value to another value.
typedef id _Nonnull(^BLUFastMapEnumerationBlock)(id value);

/// Maps each item in the enumeration to another item. The mapping is defined by the given \c block.
- (BLUFastEnumerator *)map:(BLUFastMapEnumerationBlock)block;

/// Block that maps a value to a fast enumeration object.
typedef id<NSFastEnumeration> _Nonnull(^BLUFastFlatMapEnumerationBlock)(id value);

/// Maps each item in the enumeration to an \c id<NSFastEnumeration>, then flattens it to a single
/// enumeration.
- (BLUFastEnumerator *)flatMap:(BLUFastFlatMapEnumerationBlock)block;

/// Flattens the current enumeration of enumerations to a single enumeration.
- (BLUFastEnumerator *)flatten;

/// Source of elements this enumerator is based on.
@property (readonly, nonatomic) id<NSFastEnumeration> source;

@end

@interface NSArray (BLUFastEnumerator)

/// Returns a \c BLUFastEnumerator over the receiver.
@property (readonly, nonatomic) BLUFastEnumerator *blu_enumerator;

@end

@interface NSOrderedSet (BLUFastEnumerator)

/// Returns a \c BLUFastEnumerator over the receiver.
@property (readonly, nonatomic) BLUFastEnumerator *blu_enumerator;

@end

NS_ASSUME_NONNULL_END
