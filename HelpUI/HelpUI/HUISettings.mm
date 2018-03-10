// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import <LTKit/UIColor+Utilities.h>

NS_ASSUME_NONNULL_BEGIN

@implementation HUISettings

- (instancetype)initPrivate {
  if (self = [super init]) {
    self.localizationBlock = nil;
    self.contentAspectRatio = 1.0;
    self.helpViewBackgroundColor = [[UIColor lt_colorWithHex:@"#000000"]
                                    colorWithAlphaComponent:0.15];
    self.topBoxGradientTopColor = [UIColor lt_colorWithHex:@"#202023"];
    self.topBoxGradientBottomColor = [UIColor lt_colorWithHex:@"#000000"];
    self.topBoxIconColor = [UIColor lt_colorWithHex:@"#FFFFFF"];
    self.topBoxHighlightedIconColor = [UIColor lt_colorWithHex:@"#FFFFFF"];
    self.topBoxTitleColor = [[UIColor lt_colorWithHex:@"#FFFFFF"] colorWithAlphaComponent:0.9];
    self.topBoxBodyColor = [[UIColor lt_colorWithHex:@"#FFFFFF"] colorWithAlphaComponent:0.8];
    self.boxBackgroundColor = [UIColor lt_colorWithHex:@"#000000"];

    self.topBoxTitleFontWeight = UIFontWeightBold;
    self.topBoxBodyFontWeight = UIFontWeightLight;

    self.boxShadowColor = [UIColor blackColor];
    self.boxShadowBackgroundColor = [UIColor clearColor];
  }
  return self;
}

+ (HUISettings *)instance {
  static HUISettings *instance = nil;

  if (instance == nil) {
    instance = [[HUISettings alloc] initPrivate];
  }

  return instance;
}

- (NSString *)localize:(NSString *)text {
  return self.localizationBlock ?  self.localizationBlock(text) : text;
}

@end

NS_ASSUME_NONNULL_END
