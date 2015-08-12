// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNResizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNIdentityResizingStrategy

- (CGSize)sizeForInputSize:(CGSize)size {
  return size;
}

@end

@interface PTNMaxPixelsResizingStrategy ()

/// Maximal pixels to be contained in each returned output size.
@property (nonatomic) NSUInteger maxPixels;

@end

@implementation PTNMaxPixelsResizingStrategy

- (instancetype)init {
  return nil;
}

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

  // Note: this doesn't return the largest size available since
  return CGSizeMake(floor(scaledSize.width), floor(scaledSize.height));
}

@end

@interface PTNAspectFitResizingStrategy ()

/// Size to aspect fit to.
@property (nonatomic) CGSize size;

@end

@implementation PTNAspectFitResizingStrategy

- (instancetype)init {
  return nil;
}

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

@end

@interface PTNAspectFillResizingStrategy ()

/// Size to aspect fill to.
@property (nonatomic) CGSize size;

@end

@implementation PTNAspectFillResizingStrategy

- (instancetype)init {
  return nil;
}

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

@end

NS_ASSUME_NONNULL_END
