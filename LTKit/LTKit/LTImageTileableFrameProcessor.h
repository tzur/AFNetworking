// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageFrameProcessor.h"

/// Creates framed image using an input image and tileable \c LTImageFrame.
/// Constraints on non-nil tileable textures: \c baseTexture and \c baseMask should be of the same
/// size and both dimensions need to be a power of two. \c frameMask should be a rectangle.
@interface LTImageTileableFrameProcessor : LTImageFrameProcessor

// Sets the image frame with \c angle and \c translation.
- (void)setImageFrame:(LTImageFrame *)imageFrame angle:(CGFloat)angle
          translation:(CGPoint)translation;

/// Angle of the base texture and mask. Should be in [-M_PI, M_PI] range. The default value is 0,
/// which means no change to the input frame's angle.
@property (readonly, nonatomic) CGFloat angle;
LTPropertyDeclare(CGFloat, angle, Angle);

/// Translation of the base texture and mask. The default value is \c (0, 0).
@property (readonly, nonatomic) CGPoint translation;

@end
