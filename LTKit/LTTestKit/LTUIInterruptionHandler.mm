// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "LTUIInterruptionHandler.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTUIInterruptionHandler

-(instancetype)initWithDescription:(NSString *)description
                         withBlock:(LTUIInterruptionHandlerBlock)block {
  if (self = [super init]) {
    _descriptionText = description;
    _block = block;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
