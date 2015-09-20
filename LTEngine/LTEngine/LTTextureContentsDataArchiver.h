// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsArchiver.h"

/// Archives texture's contents in memory to \c NSData. This class is commonly for user created
/// content, or in cases where the contents cannot be loaded from an existing storage.
///
/// @note the current implementation accepts only RGBA8 textures, and will assert on other formats.
@interface LTTextureContentsDataArchiver : NSObject <LTTextureContentsArchiver>
@end
