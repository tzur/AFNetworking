// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

/// Available arithmetic operations.
typedef NS_ENUM(NSUInteger, LTArithmeticOperation) {
  LTArithmeticOperationAdd = 0,
  LTArithmeticOperationSubtract = 1,
  LTArithmeticOperationMultiply = 2,
  LTArithmeticOperationDivide = 3
};

/// Processor for calculating an arithmetic operation between two input textures, \c first and \c
/// second. After processing, the \c output is set to \c first \c operation \c second.
///
/// @note only the RGB channels are affected by this arithmetic operation. The alpha channel of the
/// output will always be \c 1.
@interface LTArithmeticProcessor : LTOneShotImageProcessor

/// Initializes with two operands and an output texture. The operands must be of the same size.
- (instancetype)initWithFirstOperand:(LTTexture *)first secondOperand:(LTTexture *)second
                              output:(LTTexture *)output;

/// Arithmetic operation to use while processing.
@property (nonatomic) LTArithmeticOperation operation;

@end
