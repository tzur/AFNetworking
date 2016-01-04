// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (Photons)

/// Returns query items as a dictionary from \c NSString key to its \c NSString value. If there are
/// two query keys with the same value, the latter value will be the returned one.
@property (readonly, nonatomic) NSDictionary<NSString *, NSString *> *ptn_queryDictionary;

@end

NS_ASSUME_NONNULL_END
