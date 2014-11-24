// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"
#import "LTTexture.h"

/// Supported types of frames, categorized by square-to-rectangle mapping modes.
typedef NS_ENUM(NSUInteger, LTFrameType) {
  /// Stretching the central part of the longer dimension.
  LTFrameTypeStretch = 0,
  /// Repeating the central part of the longer dimension integer number of times.
  LTFrameTypeRepeat,
  /// Fitting the square frame in the middle of the image rectangle.
  LTFrameTypeFit,
  /// One to one mapping between the \c frameMask and the \c output texture.
  LTFrameTypeIdentity
};

#pragma mark -
#pragma mark LTImageFrame
#pragma mark -

/// Holds relevant information for creating a frame.
@interface LTImageFrame : NSObject

/// Sets the \c baseTexture, \c baseMask and \c frameMask. \c frameType defines how to map all
/// textures.
- (instancetype)initWithBaseTexture:(LTTexture *)baseTexture baseMask:(LTTexture *)baseMask
                          frameMask:(LTTexture *)frameMask frameType:(LTFrameType)frameType;

/// Sets the \c baseTexture, \c baseMask and \c frameMask. \c frameType defines how to map
/// textures. \c mapBaseToFullImageSize means that the \c baseTexture and \c baseMask will be mapped
/// to the full image size.
- (instancetype)initWithBaseTexture:(LTTexture *)baseTexture baseMask:(LTTexture *)baseMask
                          frameMask:(LTTexture *)frameMask frameType:(LTFrameType)frameType
             mapBaseToFullImageSize:(BOOL)mapBaseToFullImageSize;

/// Four channeled texture for the frame.
@property (readonly, nonatomic) LTTexture *baseTexture;

/// One channel mask for \c baseTexture.
@property (readonly, nonatomic) LTTexture *baseMask;

/// One channel mask for the frame.
@property (readonly, nonatomic) LTTexture *frameMask;

/// Type of frame mapping required.
@property (readonly, nonatomic) LTFrameType frameType;

/// Maps the \c baseTexture and \c baseMask to full image.
@property (readonly, nonatomic) BOOL mapBaseToFullImageSize;
@end

#pragma mark -
#pragma mark LTImageFrameProcessor
#pragma mark -

/// Creates framed image using an input image and \c LTImageFrame.
/// Constraints on non-nil textures: \c baseTexture and \c baseMask should be a square.
/// \c frameMask must be square as well, unless \c frameType is \c LTFrameTypeIdentity. In that
/// case, \c frameMask must be with the same aspect ratio as the output image.
@interface LTImageFrameProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture, which will have a frame added to it as the output.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Initializes the processor with another processor. Takes \c inputTexture, \c outputTexture,
/// \c widthFactor, \c color, \c globalBaseMaskAlpha, \c globalFrameMaskAlpha.
- (instancetype)initWithImageFrameProcessor:(LTImageFrameProcessor *)other;

// Holds image frame.
@property (strong, nonatomic) LTImageFrame *imageFrame;

/// Factors the width of the frame. Should be in [0.85, 1.5] range. The default value is 1, which
/// means no change to the input frame's width.
@property (nonatomic) CGFloat widthFactor;
LTPropertyDeclare(CGFloat, widthFactor, WidthFactor);

/// Color of the colorable parts of the frame as defined by \c baseMask. Components should be in
/// [0, 1] range. Default color is (0, 0, 0).
@property (nonatomic) LTVector3 color;
LTPropertyDeclare(LTVector3, color, Color);

/// Factors the entire \c baseMask alpha. Should be in [0, 1] range. The default value is 1, which
/// means to fully take \c baseMask alpha.
@property (nonatomic) CGFloat globalBaseMaskAlpha;
LTPropertyDeclare(CGFloat, globalBaseMaskAlpha, GlobalBaseMaskAlpha);

/// Factors the entire \c frameMask with opacity. Should be in [0, 1] range. The default value is 1,
/// which means no change to the \c frameMask alpha.
@property (nonatomic) CGFloat globalFrameMaskAlpha;
LTPropertyDeclare(CGFloat, globalFrameMaskAlpha, GlobalFrameMaskAlpha);

@end
