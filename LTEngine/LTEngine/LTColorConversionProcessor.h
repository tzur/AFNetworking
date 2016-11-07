// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

typedef NS_ENUM(NSUInteger, LTColorConversionMode) {
  LTColorConversionRGBToHSV = 0,
  LTColorConversionHSVToRGB = 1,
  LTColorConversionRGBToYIQ = 2,
  LTColorConversionYIQToRGB = 3,
  LTColorConversionRGBToYYYY = 4,
  LTColorConversionBGRToRGB = 5,
  LTColorConversionYCbCrFullRangeToRGB = 6,
  LTColorConversionYCbCrVideoRangeToRGB = 7
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

/// Initializes with input and auxiliary images to be converted and output to store the result.
///
/// For \c LTColorConversionYCbCrFullRangeToRGB and \c LTColorConversionYCbCrVideoRangeToRGB, the Y
/// channel is the R of \c input, Cb and Cr channels are the RG channels of \c auxiliaryInput.
- (instancetype)initWithInput:(LTTexture *)input auxiliaryInput:(LTTexture *)auxiliaryInput
                       output:(LTTexture *)output;

/// What conversion mode should be used to produce the output.
@property (nonatomic) LTColorConversionMode mode;

@end
