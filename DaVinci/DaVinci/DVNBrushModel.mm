// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNBrushModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    _brushModelVersion = 1;
    _scale = 1;
    _minScale = 0;
    _maxScale = CGFLOAT_MAX;
  }
  return self;
}

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(DVNBrushModel, brushModelVersion): @"brushModelVersion",
    @instanceKeypath(DVNBrushModel, scale): @"scale",
    @instanceKeypath(DVNBrushModel, minScale): @"minScale",
    @instanceKeypath(DVNBrushModel, maxScale): @"maxScale"
  };
}

@end

NS_ASSUME_NONNULL_END
