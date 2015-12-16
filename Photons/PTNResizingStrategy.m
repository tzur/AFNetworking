// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNResizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNIdentityResizingStrategy

- (CGSize)sizeForInputSize:(CGSize)size {
  return size;
}

- (PTNImageContentMode)contentMode {
  // Using aspect fit is arbitrary since no use of it should be made when the aspect ratio of the
  // requested size matches that of the image.
  return PTNImageContentModeAspectFit;
}

@end

@interface PTNMaxPixelsResizingStrategy ()

/// Maximal pixels to be contained in each returned output size.
@property (nonatomic) NSUInteger maxPixels;

@end

@implementation PTNMaxPixelsResizingStrategy

- (instancetype)initWithMaxPixels:(NSUInteger)maxPixels {
  if (self = [super init]) {
    self.maxPixels = maxPixels;
  }
  return self;
}

- (CGSize)sizeForInputSize:(CGSize)size {
  NSUInteger pixelCount = size.width * size.height;
  if (pixelCount <= self.maxPixels) {
    return size;
  }

  double scaleFactor = sqrt((double)self.maxPixels / pixelCount);
  CGSize scaledSize = CGSizeMake(size.width * scaleFactor, size.height * scaleFactor);

  // Note: this doesn't return the largest size available since the flooring operator doesn't take
  // into account the summed omitted values possibly being greater than 1.
  // i.e. Given an image of size 75 by 100, with max pixel size of 1024 will give an initial scaled
  // size of 27.7 by 36.95 which multiplies to 1024 exactly. How ever the floored version (27 by 36)
  // consists of only 972 pixels and both 27 * 37 and 28 * 36 give results well below 1024.
  return CGSizeMake(floor(scaledSize.width), floor(scaledSize.height));
}

- (PTNImageContentMode)contentMode {
  // Using aspect fit is crucial since it returns a size that is bounded from above by the requested
  // size.
  return PTNImageContentModeAspectFit;
}

@end

@interface PTNAspectFitResizingStrategy ()

/// Size to aspect fit to.
@property (nonatomic) CGSize size;

@end

@implementation PTNAspectFitResizingStrategy

- (instancetype)initWithSize:(CGSize)size {
  if (self = [super init]) {
    self.size = size;
  }
  return self;
}

- (CGSize)sizeForInputSize:(CGSize)size {
  CGFloat widthRatio = self.size.width / size.width;
  CGFloat heightRatio = self.size.height / size.height;

  CGFloat scaling = MIN(widthRatio, heightRatio);

  return CGSizeMake(round(size.width * scaling), round(size.height * scaling));
}

- (PTNImageContentMode)contentMode {
  return PTNImageContentModeAspectFit;
}

@end

@interface PTNAspectFillResizingStrategy ()

/// Size to aspect fill to.
@property (nonatomic) CGSize size;

@end

@implementation PTNAspectFillResizingStrategy

- (instancetype)initWithSize:(CGSize)size {
  if (self = [super init]) {
    self.size = size;
  }
  return self;
}

- (CGSize)sizeForInputSize:(CGSize)size {
  CGFloat widthRatio = self.size.width / size.width;
  CGFloat heightRatio = self.size.height / size.height;

  CGFloat scaling = MAX(widthRatio, heightRatio);

  return CGSizeMake(round(size.width * scaling), round(size.height * scaling));
}

- (PTNImageContentMode)contentMode {
  return PTNImageContentModeAspectFill;
}

@end

NS_ASSUME_NONNULL_END
