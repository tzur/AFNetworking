// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureBaseArchiver.h"

NS_ASSUME_NONNULL_BEGIN

/// Archiver that can be used for saving textures as losslessly compressed buffers using LZ4
/// compression.
@interface LTTextureLZ4Archiver : NSObject <LTTextureBaseArchiver>
@end

NS_ASSUME_NONNULL_END
