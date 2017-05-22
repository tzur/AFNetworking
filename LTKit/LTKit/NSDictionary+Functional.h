// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (Functional)

/// Callback block used with \c lt_filter:.
typedef BOOL (^LTDictionaryFilterBlock)(KeyType key, ObjectType obj);

/// Filters the dictionary using the specified filter \c block.
///
/// Returns a filtered dictionary containing all and only the entries of the receiver that \c block
/// has returned \c YES for.
- (instancetype)lt_filter:(NS_NOESCAPE LTDictionaryFilterBlock)block;

@end

NS_ASSUME_NONNULL_END
