// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUIModelSettings.h"

NS_ASSUME_NONNULL_BEGIN

@implementation HUIModelSettings

static HUILocalizationBlock _localizationBlock = nil;

+ (nullable HUILocalizationBlock)localizationBlock {
  return _localizationBlock;
}

+ (void)setLocalizationBlock:(nullable HUILocalizationBlock)localizationBlock {
  _localizationBlock = localizationBlock;
}

@end

NS_ASSUME_NONNULL_END
