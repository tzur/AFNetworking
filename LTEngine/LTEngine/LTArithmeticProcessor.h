// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/// Available arithmetic operations.
typedef NS_ENUM(NSUInteger, LTArithmeticOperation) {
  LTArithmeticOperationAdd = 0,
  LTArithmeticOperationSubtract = 1,
  LTArithmeticOperationMultiply = 2,
  LTArithmeticOperationDivide = 3,
  LTArithmeticOperationMax = 4,
  LTArithmeticOperationMin = 5
};

/// Processor for calculating an elementwise arithmetic operation between two input textures,
/// \c first and \c second. After processing, the \c output is set to
/// <tt>first operation second</tt>.
///
/// @important Only the RGB channels are affected by this arithmetic \c operation.
/// The alpha channel of the output will always be \c 1.
@interface LTArithmeticProcessor : LTOneShotImageProcessor

/// Initializes with two operands and an output texture. The operands must be of the same size.
/// The output texture may be the same as one of the input textures for in-place processing.
- (instancetype)initWithFirstOperand:(LTTexture *)first secondOperand:(LTTexture *)second
                              output:(LTTexture *)output;

/// Arithmetic operation to use while processing.
@property (nonatomic) LTArithmeticOperation operation;

@end

NS_ASSUME_NONNULL_END
