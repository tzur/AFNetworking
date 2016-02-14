// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (Photons)

typedef NSDictionary<NSString *, NSString *> PTNQueryDictionary;

/// Returns query items as a dictionary from \c NSString key to its \c NSString value. If there are
/// two query keys with the same value, the latter value will be the returned one.
+ (PTNQueryDictionary *)ptn_dictionaryWithQuery:(NSArray<NSURLQueryItem *> *)query;

/// Returns a new \c NSURL object composed of this URL by appending of \c query. If there are two
/// query keys with the same name, both will be added into the retuned \c NSURL.
- (NSURL *)ptn_URLByAppendingQuery:(NSArray<NSURLQueryItem *> *)query;

/// Returns query items as a dictionary from \c NSString key to its \c NSString value. If there are
/// two query keys with the same value, the latter value will be the returned one.
@property (readonly, nonatomic) PTNQueryDictionary *ptn_queryDictionary;

@end

NS_ASSUME_NONNULL_END
