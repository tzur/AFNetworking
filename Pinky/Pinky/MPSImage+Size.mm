// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MPSImage+Size.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@implementation MPSImage (Size)

- (MTLSize)pnk_size {
  return {
    .width = self.width,
    .height = self.height,
    .depth = self.featureChannels
  };
}

@end

#endif

NS_ASSUME_NONNULL_END
