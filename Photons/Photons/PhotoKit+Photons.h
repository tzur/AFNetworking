// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (Photons) <PTNAssetDescriptor>
@end

@interface PHCollection (Photons) <PTNAlbumDescriptor>
@end

NS_ASSUME_NONNULL_END
