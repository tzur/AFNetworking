// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbumChangeset.h"

NS_ASSUME_NONNULL_BEGIN

@class PHFetchResult, PHFetchResultChangeDetails;

@interface PTNAlbumChangeset (PhotoKit)

/// Constructs a new null changeset from PhotoKit \c fetchResult object (set as the \c afterAlbum)
/// produced from the given \c url.
+ (instancetype)changesetWithURL:(NSURL *)url photoKitFetchResult:(PHFetchResult *)fetchResult;

/// Constructs a new changeset from PhotoKit \c PHFetchResultChangeDetails object produces by
/// observing the given \c url.
+ (instancetype)changesetWithURL:(NSURL *)url
           photoKitChangeDetails:(PHFetchResultChangeDetails *)changeDetails;

@end

NS_ASSUME_NONNULL_END
