// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataCache.h"

NS_ASSUME_NONNULL_BEGIN

/// Implementation of \c PTNDataCache based on top of \c NSURLCache.
@interface NSURLCache (Photons) <PTNDataCache>
@end

NS_ASSUME_NONNULL_END
