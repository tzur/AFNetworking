// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "CIImage+Swizzle.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CIImage (Swizzle)

- (CIImage *)lt_swizzledImage {
  CIFilter *filter = [CIFilter filterWithName:@"CIColorMatrix"];
  [filter setValue:self forKey:kCIInputImageKey];
  [filter setValue:[CIVector vectorWithX:0 Y:0 Z:1 W:0] forKey:@"inputRVector"];
  [filter setValue:[CIVector vectorWithX:1 Y:0 Z:0 W:0] forKey:@"inputBVector"];
  return filter.outputImage;
}

@end

NS_ASSUME_NONNULL_END
