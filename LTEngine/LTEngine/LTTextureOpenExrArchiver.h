// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LTTextureBaseArchiver.h"

NS_ASSUME_NONNULL_BEGIN

/// Archiver that can be used for saving half-float RGBA textures as losslessly compressed buffers
/// using OpenEXR PIZ compression.
@interface LTTextureOpenExrArchiver : NSObject <LTTextureBaseArchiver>
@end

NS_ASSUME_NONNULL_END
