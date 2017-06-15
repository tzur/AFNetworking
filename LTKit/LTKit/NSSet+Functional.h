// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

@interface NSSet<ObjectType> (Functional)

/// Callback block used with \c lt_map: method.
typedef id _Nonnull(^LTSetMapBlock)(ObjectType _Nonnull object);

/// Maps the set using the specified map \c block.
///
/// Returns a new set with the results of calling the provided \c block on every element in this
/// set. If \c block returns \c nil an \c NSInvalidArgumentException is raised.
///
/// <b>Example for mapping a set:</b>
/// @code
/// NSSet<NSNumber *> *source = ...; // Set with numbers 0 to 10.
/// NSSet<NSNumber *> *powersOf2 = [source lt_map:^(NSNumber *object) {
///   return @(pow(2, [object floatValue]));
/// }];
/// // powersOf2 = [1, 2, 4, ..., 2^10]
/// @endcode
- (NSSet *)lt_map:(NS_NOESCAPE LTSetMapBlock)block;

/// Callback block used with \c lt_filter:.
typedef BOOL (^LTSetFilterBlock)(ObjectType _Nonnull object);

/// Filters the set using the specified filter \c block.
///
/// Returns a filtered set containing all and only the items of the receiver that \c block has
/// returned \c YES for.
- (instancetype)lt_filter:(NS_NOESCAPE LTSetFilterBlock)block;

@end

NS_ASSUME_NONNULL_END
