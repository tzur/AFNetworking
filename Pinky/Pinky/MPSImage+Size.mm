// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MPSImage+Size.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MPSImage (Size)

- (MTLSize)pnk_size {
  return {
    .width = self.width,
    .height = self.height,
    .depth = self.featureChannels
  };
}

- (NSUInteger)pnk_textureArrayDepth {
  return (self.featureChannels + 3) / 4;
}

- (BOOL)pnk_isTextureArray {
  return self.featureChannels > 4;
}

- (BOOL)pnk_isSingleTexture {
  return self.featureChannels <= 4;
}

- (MTLSize)pnk_textureArraySize {
  return {
    .width = self.width,
    .height = self.height,
    .depth = self.pnk_textureArrayDepth
  };
}

@end

NS_ASSUME_NONNULL_END
