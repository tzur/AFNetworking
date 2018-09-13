// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import <MediaPlayer/MediaPlayer.h>

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting \c MPMediaItem by adding \c PTNAssetDescriptor's functionality.
@interface MPMediaItem (Photons) <PTNAssetDescriptor>

/// Identifier of the Photons object.
@property (readonly, nonatomic) NSURL *ptn_identifier;

@end

NS_ASSUME_NONNULL_END
