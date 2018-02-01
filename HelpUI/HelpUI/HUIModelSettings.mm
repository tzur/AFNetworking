// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

@implementation HUIModelSettings

static HUILocalizationBlock _localizationBlock = nil;

+ (nullable HUILocalizationBlock)localizationBlock {
  return _localizationBlock;
}

+ (void)setLocalizationBlock:(nullable HUILocalizationBlock)localizationBlock {
  _localizationBlock = localizationBlock;
}

+ (NSString *)localize:(NSString *)text {
  return HUIModelSettings.localizationBlock ?  HUIModelSettings.localizationBlock(text) : text;
}

@end

NS_ASSUME_NONNULL_END
