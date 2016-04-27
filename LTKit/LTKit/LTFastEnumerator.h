// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Fast enumerator that wraps a \c source enumeration and supports basic functional operators such
/// as \c map, \c flatMap and \c flatten. The operators are lazy and thus do not execute until they
/// are required by enumeration.
///
/// @note the source enumeration is referenced and strongly held by this enumerator, but the
/// enumerator is not considered as an owner of the source. Therefore, it is not copied and it can
/// be changed after the enumerator has been created.
@interface LTFastEnumerator : NSObject <NSCopying, NSFastEnumeration>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new enumerator with the given \c source. The enumerator holds a reference to the
/// source, but it is not being copied. Additional changes to the \c source after the enumerator's
/// initialization will be reflected on the enumerator as well.
- (instancetype)initWithSource:(id<NSFastEnumeration>)source;

/// Block that maps a value to another value.
typedef id _Nonnull(^LTFastMapEnumerationBlock)(id value);

/// Maps each item in the enumeration to another item. The mapping is defined by the given \c block.
- (LTFastEnumerator *)map:(LTFastMapEnumerationBlock)block;

/// Block that maps a value to a fast enumeration object.
typedef id<NSFastEnumeration> _Nonnull(^LTFastFlatMapEnumerationBlock)(id value);

/// Maps each item in the enumeration to an \c id<NSFastEnumeration>, then flattens it to a single
/// enumeration.
- (LTFastEnumerator *)flatMap:(LTFastFlatMapEnumerationBlock)block;

/// Flattens the current enumeration of enumerations to a single enumeration.
- (LTFastEnumerator *)flatten;

/// Source of elements this enumerator is based on.
@property (readonly, nonatomic) id<NSFastEnumeration> source;

@end

@interface NSArray (LTFastEnumerator)

/// Returns a \c LTFastEnumerator over the receiver.
@property (readonly, nonatomic) LTFastEnumerator *lt_enumerator;

@end

@interface NSOrderedSet (LTFastEnumerator)

/// Returns a \c LTFastEnumerator over the receiver.
@property (readonly, nonatomic) LTFastEnumerator *lt_enumerator;

@end

NS_ASSUME_NONNULL_END
