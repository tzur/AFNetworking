// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Returns a custom URL made with \c scheme, \c host and \c query as its scheme, host and query
/// items respectively.
NSURL *PTNCreateURL(NSString * _Nullable scheme, NSString * _Nullable host,
                    NSArray<NSURLQueryItem *> * _Nullable query);

NS_ASSUME_NONNULL_END
