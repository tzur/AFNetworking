// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import <MediaPlayer/MediaPlayer.h>

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting \c MPMediaItemCollection by adding \c PTNAlbumDescriptor's functionality.
@interface MPMediaItemCollection (Photons) <PTNAlbumDescriptor>
@end

NS_ASSUME_NONNULL_END
