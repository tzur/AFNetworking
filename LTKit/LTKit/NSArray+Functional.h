// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Adds common functional methods to \c NSArray, like map and reduce.
@interface NSArray<ObjectType> (Functional)

/// Callback block used with \c lt_map: method.
typedef id _Nonnull (^LTArrayMapBlock)(ObjectType _Nonnull object);

/// Returns a new array with the results of calling the provided \c block on every element in this
/// array. If \c block returns \c nil an \c NSInvalidArgumentException is raised.
///
/// <b>Example for mapping an array:</b>
/// @code
/// NSArray<NSNumber *> *source = ...; // Array with numbers 0 to 10.
/// NSArray<NSNumber *> *powersOf2 = [source lt_map:^(NSNumber *object) {
///   return pow(2, [object floatValue]);
/// }];
/// // powersOf2 = [1, 2, 4, ..., 2^10]
/// @endcode
- (NSArray *)lt_map:(LTArrayMapBlock)block;

/// Callback block used with \c lt_reduce:initial:.
typedef id _Nonnull (^LTArrayReduceBlock)(id _Nonnull value, ObjectType object);

/// Applies the given \c block against an accumulator and each element of the array to reduce it to
/// a single value. The \c initialValue argument is passed as the accumulator to the reduce block
/// executed for the first array element.
///
/// <b>Example for reducing an array:</b>
/// @code
/// NSArray<NSNumber *> *source = ...; // Array with numbers 0 to 10.
/// NSNumber *sum = [someArray lt_reduce:^(id _Nullable value, NSNumber *object) {
///   return @([object unsignedIntegerValue] + [value unsignedIntegerValue]);
/// } initialValue:@0];
/// // sum = 0 + 1 + 2 + ... + 10
/// @endcode
- (id)lt_reduce:(LTArrayReduceBlock)block initial:(id)initialValue;

@end

NS_ASSUME_NONNULL_END
