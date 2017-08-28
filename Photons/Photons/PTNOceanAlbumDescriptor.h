// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// Descriptor for Ocean albums.
@interface PTNOceanAlbumDescriptor : NSObject <PTNAlbumDescriptor>

/// Initializes with the given \c albumURL whose \c ptn_oceanURLType must be
/// \c PTNOceanURLTypeAlbum.
- (instancetype)initWithAlbumURL:(NSURL *)albumURL NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
