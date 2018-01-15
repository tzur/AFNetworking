// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionVideoPageViewModel.h"

#import "SPXColorScheme.h"
#import "UIFont+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionVideoPageViewModel ()

/// Page view title string.
@property (readonly, nonatomic) NSString *titleText;

/// Page view secondary string. If \c nil no subtitle is shown.
@property (readonly, nonatomic, nullable) NSString *subtitleText;

/// Color for \c titleText.
@property (readonly, nonatomic) UIColor *titleTextColor;

/// Color for \c subtitleText.
@property (readonly, nonatomic) UIColor *subtitleTextColor;

@end

@implementation SPXSubscriptionVideoPageViewModel

@synthesize videoURL = _videoURL;
@synthesize videoBorderColor = _videoBorderColor;

- (instancetype)initWithVideoURL:(NSURL *)videoURL titleText:(NSString *)titleText
                    subtitleText:(nullable NSString *)subtitleText {
  return [self initWithVideoURL:videoURL titleText:titleText subtitleText:subtitleText
                    colorScheme:nn([JSObjection defaultInjector][[SPXColorScheme class]])];
}

- (instancetype)initWithVideoURL:(NSURL *)videoURL titleText:(NSString *)titleText
                    subtitleText:(nullable NSString *)subtitleText
                     colorScheme:(SPXColorScheme *)colorScheme {
  return [self initWithVideoURL:videoURL titleText:titleText subtitleText:subtitleText
               videoBorderColor:colorScheme.borderColor titleTextColor:colorScheme.textColor
              subtitleTextColor:colorScheme.textColor];
}

- (instancetype)initWithVideoURL:(NSURL *)videoURL titleText:(NSString *)titleText
                    subtitleText:(nullable NSString *)subtitleText
                videoBorderColor:(nullable UIColor *)videoBorderColor
                  titleTextColor:(UIColor *)titleTextColor
               subtitleTextColor:(UIColor *)subtitleTextColor {
  if (self = [super init]) {
    _videoURL = videoURL;
    _titleText = [titleText copy];
    _subtitleText = [subtitleText copy];
    _videoBorderColor = videoBorderColor;
    _titleTextColor = titleTextColor;
    _subtitleTextColor = subtitleTextColor;
  }
  return self;
}

- (NSAttributedString *)title {
  return [[NSAttributedString alloc] initWithString:self.titleText attributes:@{
    NSForegroundColorAttributeName: self.titleTextColor,
    NSFontAttributeName: [UIFont spx_fontWithSizeRatio:0.04 minSize:18 maxSize:26
                                                weight:UIFontWeightBold]
  }];
}

- (nullable NSAttributedString *)subtitle {
  if (!self.subtitleText) {
    return nil;
  }

  return [[NSAttributedString alloc] initWithString:self.subtitleText attributes:@{
    NSForegroundColorAttributeName: self.subtitleTextColor,
    NSFontAttributeName: [UIFont spx_standardFontWithSizeRatio:0.019 minSize:13 maxSize:16]
  }];
}

@end

NS_ASSUME_NONNULL_END
