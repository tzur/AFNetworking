// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

/// Available arithmetic operations.
typedef NS_ENUM(NSUInteger, LTMaskedArithmeticOperation) {
  LTMaskedArithmeticOperationSubtract = 0
};

/// Processor for calculating an arithmetic operation between two input textures, \c first and \c
/// second. After processing, the \c output is set to \c first \c operation \c second where
/// \c mask is \c 1, and \c 0 elsewhere.
///
/// @note only the RGB channels are affected by this arithmetic operation. The alpha channel of the
/// output will always be \c 1.
@interface LTMaskedArithmeticProcessor : LTOneShotImageProcessor

/// Initializes with two operands, a \c mask and an output texture. The operands and the \c mask
/// texture must be of the same size.
- (instancetype)initWithFirstOperand:(LTTexture *)first secondOperand:(LTTexture *)second
                                mask:(LTTexture *)mask output:(LTTexture *)output;

/// Arithmetic operation to use while processing.
@property (nonatomic) LTMaskedArithmeticOperation operation;

@end
