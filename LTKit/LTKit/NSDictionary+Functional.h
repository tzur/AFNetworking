// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (Functional)

/// Callback block used with \c lt_mapValues: method.
typedef id _Nonnull(^LTDictionaryMapBlock)(KeyType key, ObjectType obj);

/// Maps the dictionary values using the specified map \c block.
///
/// Returns a new dictionary with the same keys, the value of each key is the result of calling the
/// provided \c block on that key and its value in the receiver. If \c block returns \c nil an
/// \c NSInvalidArgumentException is raised.
///
/// <b>Example for mapping dictionary values:</b>
/// @code
/// NSDictionary<NSNumber *, NSNumber *> *source = @{1: 1, 2: 2, ... 10: 10};
/// NSDictionary<NSNumber *, NSNumber *> *powersOf2 =
///     [source lt_mapValues:^(NSNumber *key, NSNumber *value) {
///   return key * value;
/// }];
/// // powersOf2 = {1: 2, 2: 4, 3: 9, ..., 10: 100}
/// @endcode
- (NSDictionary *)lt_mapValues:(NS_NOESCAPE LTDictionaryMapBlock)block;

/// Callback block used with \c lt_filter:.
typedef BOOL (^LTDictionaryFilterBlock)(KeyType key, ObjectType obj);

/// Filters the dictionary using the specified filter \c block.
///
/// Returns a filtered dictionary containing all and only the entries of the receiver that \c block
/// has returned \c YES for.
- (instancetype)lt_filter:(NS_NOESCAPE LTDictionaryFilterBlock)block;

@end

NS_ASSUME_NONNULL_END
