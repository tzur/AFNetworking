// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNResizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNResizingStrategy

+ (id<PTNResizingStrategy>)identity {
  return [[PTNIdentityResizingStrategy alloc] init];
}

+ (id<PTNResizingStrategy>)maxPixels:(NSUInteger)maxPixels {
  return [[PTNMaxPixelsResizingStrategy alloc] initWithMaxPixels:maxPixels];
}

+ (id<PTNResizingStrategy>)aspectFit:(CGSize)size {
  return [[PTNAspectFitResizingStrategy alloc] initWithSize:size];
}

+ (id<PTNResizingStrategy>)aspectFill:(CGSize)size {
  return [[PTNAspectFillResizingStrategy alloc] initWithSize:size];
}

+ (id<PTNResizingStrategy>)contentMode:(PTNImageContentMode)contentMode
                                       size:(CGSize)size {
  switch (contentMode) {
    case PTNImageContentModeAspectFill:
      return [[PTNAspectFillResizingStrategy alloc] initWithSize:size];
    case PTNImageContentModeAspectFit:
      return [[PTNAspectFitResizingStrategy alloc] initWithSize:size];
  }
}

@end

@implementation PTNIdentityResizingStrategy

- (CGSize)sizeForInputSize:(CGSize)size {
  return size;
}

- (BOOL)inputSizeBoundedBySize:(CGSize __unused)size {
  // For any size \c s \c ([self sizeForInputSize:s]) returns exactly \c s. Hence there exists
  // no size such that the value returned for it by \c ([self sizeForInputSize]) bounds every other
  // size returned by \c ([self sizeForInputSize]). Since that would imply that there exists a size
  // that bounds all other sizes.
  return NO;
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

- (BOOL)inputSizeBoundedBySize:(CGSize)size {
  // While extremely inefficient this single dimension comparison is the best certainty possible
  // without knowing the aspect ratio of the original size.
  // For example the only size to bound a \c PTNMaxPixelResizingStrategy with a max pixels value
  // of \c 512 will be \c (512, 512).
  // Obviously containing a lot more than \c 512 pixels, this is the only size that bounds from
  // above all sizes with less than or equal to \c 512 pixels. Due to edge cases such as \c (1, 512)
  // and \c (512, 1).
  return MIN(size.height, size.width) >= self.maxPixels;
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

- (BOOL)inputSizeBoundedBySize:(CGSize)size {
  return size.height >= self.size.height && size.width >= self.size.width;
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

- (BOOL)inputSizeBoundedBySize:(CGSize __unused)size {
  // Due to the nature of \c PTNImageContentModeAspectFill there is not size that bounds all sizes
  // returned by this strategy.
  // Let there be a \c PTNAspectFillResizingStrategy of size \c (a, b). Assume by contradiction
  // that there exists some size \c (c, d) such that the returned value of
  // \c ([self sizeForInputSize:]) with it is \c (e, f). And assume \c (e, f) bounds from above any
  // size returned by the strategy.
  // However the size \c (e, 1) supplied to this strategy will return the size \c (64e, 64) which is
  // clearly not bound by (e, f) in width.
  return NO;
}

- (PTNImageContentMode)contentMode {
  return PTNImageContentModeAspectFill;
}

@end

NS_ASSUME_NONNULL_END
