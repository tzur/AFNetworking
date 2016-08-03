// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRPurchase.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRPurchase

- (instancetype)initWithPayment:(SKPayment *)payment
                    updateBlock:(BZRTransactionUpdateBlock)updateBlock {
  LTParameterAssert(updateBlock, @"nil updateBlock isn't allowed");
  if (self = [super init]) {
    _payment = [payment copy];
    _updateBlock = updateBlock;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
