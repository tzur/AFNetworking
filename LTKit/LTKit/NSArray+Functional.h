// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Adds common functional methods to \c NSArray, like map and reduce.
@interface NSArray<ObjectType> (Functional)

/// Callback block used with \c lt_map: method.
typedef id _Nonnull(^LTArrayMapBlock)(ObjectType _Nonnull object);

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
- (NSArray *)lt_map:(NS_NOESCAPE LTArrayMapBlock)block;

/// Callback block used with \c lt_compactMap: method.
typedef id _Nullable(^LTArrayCompactMapBlock)(ObjectType _Nonnull object);

/// Returns a new array with the results of calling the provided \c block on every element in this
/// array and filtering out values that have been mapped by the \c block to \c nil.
///
/// <b>Example for compact mapping an array:</b>
/// @code
/// NSArray<NSNumber *> *source = ...; // Array with numbers 0 to 10.
/// NSArray<NSNumber *> *oddSquares = [source lt_compactMap:^(NSNumber *object) {
///   NSUInteger number = object.unsignedIntegerValue;
///   return (number % 2 == 1) ? @(number * number) : nil;
/// }];
/// oddSquares = [1, 9, 25, 49, 81]
/// @endcode
- (NSArray *)lt_compactMap:(NS_NOESCAPE LTArrayCompactMapBlock)block;

/// Callback block used with \c lt_reduce:initial:.
typedef id _Nonnull(^LTArrayReduceBlock)(id _Nonnull value, ObjectType object);

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
- (id)lt_reduce:(NS_NOESCAPE LTArrayReduceBlock)block initial:(id)initialValue;

/// Callback block used with \c lt_filter:.
typedef BOOL (^LTArrayFilterBlock)(ObjectType _Nonnull object);

/// Filters the array using the specified filter \c block.
///
/// Returns a filtered array containing all and only the items of the receiver that \c block has
/// returned \c YES for.
- (NSArray<ObjectType> *)lt_filter:(NS_NOESCAPE LTArrayFilterBlock)block;

/// Finds the first item in the array that passed the specified filter \c block.
///
/// Returns a single object that is the first item that \c block has returned \c YES for, or \c nil
/// if \c block has returned \c NO for all array's elements.
- (nullable ObjectType)lt_find:(NS_NOESCAPE LTArrayFilterBlock)block;

/// Callback block used with \c lt_max: and \c lt_min: methods. Returns \c YES if \c a should be
/// ordered before \c b (in ascending order).
typedef BOOL (^LTArrayCompareBlock)(ObjectType _Nonnull a, ObjectType _Nonnull b);

/// Returns the maximum element in the array, using the given predicate as the comparison between
/// elements. Returns \c nil If the array is empty.
/// The predicate must be a strict weak ordering over the elements. That is, for any elements a, b,
/// and c, the following conditions must hold:
///
/// - <tt>areInIncreasingOrder(a, a)</tt> is always false. (Irreflexivity)
///
/// - If <tt>areInIncreasingOrder(a, b)</tt> and <tt>areInIncreasingOrder(b, c)</tt> are both true,
///   then <tt>areInIncreasingOrder(a, c)</tt> is also true. (Transitive comparability)
///
/// - Two elements are incomparable if neither is ordered before the other according to the
///   predicate. If a and b are incomparable, and b and c are incomparable, then a and c are also
///   incomparable. (Transitive incomparability)
///
/// @example Finding the maximum object in an array.
/// @code
/// NSArray<NSString *> *words = @[@"The", @"quick", @"brown", @"fox", @"jumped", @"over", @"me"];
/// NSString *longestWord = [words lt_max:^BOOL(NSString * _Nonnull a, NSString * _Nonnull b) {
///  return a.length < b.length;
/// }];
/// // longestWord == @"jumped"
/// @endcode
- (nullable ObjectType)lt_max:(NS_NOESCAPE LTArrayCompareBlock)areInIncreasingOrder;

/// Returns the mimum element in the array using the given predicate as the comparison between
/// elements. Returns \c nil If the array is empty.
/// The predicate must be a strict weak ordering over the elements. That is, for any elements a, b,
/// and c, the following conditions must hold:
///
/// - <tt>areInIncreasingOrder(a, a)</tt> is always false. (Irreflexivity)
///
/// - If <tt>areInIncreasingOrder(a, b)</tt> and <tt>areInIncreasingOrder(b, c)</tt> are both true,
///   then <tt>areInIncreasingOrder(a, c)</tt> is also true. (Transitive comparability)
///
/// - Two elements are incomparable if neither is ordered before the other according to the
///   predicate. If a and b are incomparable, and b and c are incomparable, then a and c are also
///   incomparable. (Transitive incomparability)
///
/// @example Finding the mimmum object in an array.
/// @code
/// NSArray<NSString *> *words = @[@"The", @"quick", @"brown", @"fox", @"jumped", @"over", @"me"];
/// NSString *shortestWord = [words lt_min:^BOOL(NSString * _Nonnull a, NSString * _Nonnull b) {
///  return a.length < b.length;
/// }];
/// // shortestWord == @"me"
/// @endcode
- (nullable ObjectType)lt_min:(NS_NOESCAPE LTArrayCompareBlock)areInIncreasingOrder;

/// Callback block used to classify objects of an array.
///
/// \c object is the array element to classify. The block returns a label for that item. The
/// returned label must conform to \c NSCopying in order to be used as a key in an \c NSDictionary.
typedef id<NSCopying> _Nonnull(^LTArrayClassifierBlock)(ObjectType _Nonnull object);

/// Classifies all the objects in an array using the given \c classifier.
///
/// Returns a dictionary in which keys are labels returned by the classifier and the value for each
/// key is an array containing the objects that matched that label.
///
/// <b>Example for classifying an array:</b>
/// @code
/// // Array with integer numbers -5 to 5.
/// NSArray<NSNumber *> *source = ...;
/// NSDictionary<NSNumber *, NSNumber *> *classification =
///     [source lt_classify:^NSNumber *(NSNumber *value) {
///       return @([value integerValue] >= 0);
///     }];
/// // classification = @{
/// //   @YES: @[@0, @1, @2, @3, @4, @5],
/// //   @NO: @[@-5, @-4, @-3, @-2 ,@-1]
/// // }
/// @endcode
- (NSDictionary<id<NSCopying>, NSArray<ObjectType> *> *)
    lt_classify:(NS_NOESCAPE LTArrayClassifierBlock)block;

@end

NS_ASSUME_NONNULL_END
