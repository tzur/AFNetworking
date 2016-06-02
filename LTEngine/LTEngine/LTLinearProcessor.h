// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "LTOneShotImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Processor for applying linear transformations. Supports in situ processing.
@interface LTLinearProcessor : LTOneShotImageProcessor

/// Initializes with the given \c input and \c output. Given textures must be of the same size.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// 4-by-4 matrix to be multiplied with each pixel of \c input. Default value is
/// \c GLKMatrix4Identity.
@property (nonatomic) GLKMatrix4 matrix;

/// Constant value added to the result obtained by multiplying \c matrix with each pixel of
/// \c input. Default value is \c LTVector4::zeros().
@property (nonatomic) LTVector4 constant;

@end

NS_ASSUME_NONNULL_END
