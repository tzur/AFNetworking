// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

typedef NS_ENUM(NSUInteger, LTColorConversionMode) {
  LTColorConversionRGBToHSV = 0,
  LTColorConversionHSVToRGB = 1,
  LTColorConversionRGBToYIQ = 2,
  LTColorConversionYIQToRGB = 3,
  LTColorConversionRGBToYYYY = 4,
};

/// Converts from one colorspace to another.
///
/// @note When using \c LTColorConversionRGBToYIQ all YIQ output channels are rescaled and offset to
/// fit the range supported by the pixel format of \c input. This is also the input expected for
/// \c LTColorConversionYIQToRGB which in turn performs the inverse of the scale and offset
/// operation done in \c LTColorConversionRGBToYIQ.
@interface LTColorConversionProcessor : LTOneShotImageProcessor

/// Initializes with input image to be converted and output to store the result.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// What conversion mode should be used to produce the output.
@property (nonatomic) LTColorConversionMode mode;

@end
