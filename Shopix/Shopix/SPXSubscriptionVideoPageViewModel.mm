// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionVideoPageViewModel.h"

#import "SPXColorScheme.h"

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

- (instancetype)initWithVideoURL:(NSURL *)videoURL titleText:(NSString *)titleText
                    subtitleText:(nullable NSString *)subtitleText {
  return [self initWithVideoURL:videoURL titleText:titleText subtitleText:subtitleText
                    colorScheme:nn([JSObjection defaultInjector][[SPXColorScheme class]])];
}

- (instancetype)initWithVideoURL:(NSURL *)videoURL titleText:(NSString *)titleText
                    subtitleText:(nullable NSString *)subtitleText
                     colorScheme:(SPXColorScheme *)colorScheme {
  return [self initWithVideoURL:videoURL titleText:titleText subtitleText:subtitleText
                 titleTextColor:colorScheme.textColor subtitleTextColor:colorScheme.textColor];
}

- (instancetype)initWithVideoURL:(NSURL *)videoURL titleText:(NSString *)titleText
                    subtitleText:(nullable NSString *)subtitleText
                  titleTextColor:(UIColor *)titleTextColor
               subtitleTextColor:(UIColor *)subtitleTextColor {
  if (self = [super init]) {
    _videoURL = videoURL;
    _titleText = [titleText copy];
    _subtitleText = [subtitleText copy];
    _titleTextColor = titleTextColor;
    _subtitleTextColor = subtitleTextColor;
  }
  return self;
}

- (NSAttributedString *)title {
  auto windowHeight = [UIApplication sharedApplication].keyWindow.bounds.size.height;
  auto fontSize = std::clamp(windowHeight * 0.04, 18, 26);
  return [[NSAttributedString alloc] initWithString:self.titleText attributes:@{
    NSForegroundColorAttributeName: self.titleTextColor,
    NSFontAttributeName: [UIFont systemFontOfSize:fontSize weight:UIFontWeightBold]
  }];
}

- (nullable NSAttributedString *)subtitle {
  if (!self.subtitleText) {
    return nil;
  }

  auto windowHeight = [UIApplication sharedApplication].keyWindow.bounds.size.height;
  auto fontSize = std::clamp(windowHeight * 0.019, 13, 16);
  return [[NSAttributedString alloc] initWithString:self.subtitleText attributes:@{
    NSForegroundColorAttributeName: self.subtitleTextColor,
    NSFontAttributeName: [UIFont systemFontOfSize:fontSize weight:UIFontWeightLight]
  }];
}

@end

NS_ASSUME_NONNULL_END
