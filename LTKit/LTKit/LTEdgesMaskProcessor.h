// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// Types of edges that the processor can create.
typedef NS_ENUM(NSUInteger, LTEdgesMode) {
  LTEdgesModeGrey = 0,
  LTEdgesModeColor
};

/// @class LTEdgesMaskProcessor creates an edges image that can be used as a mask in more complex
/// image processing algorithms, such as NPR. The result of the computation at each pixel equals to:
/// abs(dx) + abs(dy).
@interface LTEdgesMaskProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture to be adjusted and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Determines the type of the edges. Default value is LTEdgesModeGrey.
@property (nonatomic) LTEdgesMode edgesMode;

@end
