// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNResizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

/// Category for serializing and deserializing a resizing strategy into and from an \c NSURL.
@interface NSURL (PTNResizingStrategy)

/// Returns a new \c NSURL composed from this URL with additional query fields identifying
/// \c strategy in a one-to-one manner or an unchanged URL if \c strategy could not be coded into
/// a URL query.
- (NSURL *)ptn_URLWithResizingStrategy:(id<PTNResizingStrategy>)strategy;

/// Returns a resizing strategy decoded from this URL's query fields or \c nil if this URL doesn't
/// have a valid resizing strategy coded into its query.
- (nullable id<PTNResizingStrategy>)ptn_resizingStrategy;

@end

NS_ASSUME_NONNULL_END
