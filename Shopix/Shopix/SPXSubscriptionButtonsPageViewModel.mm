// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonsPageViewModel.h"

#import <LTKit/NSArray+Functional.h>

#import "SPXColorScheme.h"
#import "SPXSubscriptionDescriptor.h"
#import "UIFont+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionButtonsPageViewModel ()

/// Page view title string.
@property (readonly, nonatomic) NSString *titleText;

/// Page view secondary string. If \c nil no subtitle is shown.
@property (readonly, nonatomic, nullable) NSString *subtitleText;

/// Color for \c titleText.
@property (readonly, nonatomic) UIColor *titleTextColor;

/// Color for \c subtitleText.
@property (readonly, nonatomic) UIColor *subtitleTextColor;

/// Indicates if the page's background video should be playing.
@property (readwrite, nonatomic) BOOL shouldPlayVideo;

@end

@implementation SPXSubscriptionButtonsPageViewModel

@synthesize backgroundVideoURL = _backgroundVideoURL;
@synthesize subscriptionDescriptors = _subscriptionDescriptors;
@synthesize preferredSubscriptionIndex = _preferredSubscriptionIndex;

- (instancetype)initWithTitleText:(NSString *)titleText
                     subtitleText:(nullable NSString *)subtitleText
          subscriptionDescriptors:(NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors
           highlightedButtonIndex:(nullable NSNumber *)highlightedButtonIndex
               backgroundVideoURL:(NSURL *)backgroundVideoURL {
  return [self initWithTitleText:titleText subtitleText:subtitleText
         subscriptionDescriptors:subscriptionDescriptors
          highlightedButtonIndex:highlightedButtonIndex backgroundVideoURL:backgroundVideoURL
                     colorScheme:nn([JSObjection defaultInjector][[SPXColorScheme class]])];
}

- (instancetype)initWithTitleText:(NSString *)titleText
                     subtitleText:(nullable NSString *)subtitleText
          subscriptionDescriptors:(NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors
           highlightedButtonIndex:(nullable NSNumber *)highlightedButtonIndex
               backgroundVideoURL:(NSURL *)backgroundVideoURL
                      colorScheme:(SPXColorScheme *)colorScheme {
  return [self initWithTitleText:titleText subtitleText:subtitleText
         subscriptionDescriptors:subscriptionDescriptors
          highlightedButtonIndex:highlightedButtonIndex backgroundVideoURL:backgroundVideoURL
                  titleTextColor:colorScheme.textColor subtitleTextColor:colorScheme.textColor];
}

- (instancetype)initWithTitleText:(NSString *)titleText
                     subtitleText:(nullable NSString *)subtitleText
          subscriptionDescriptors:(NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors
           highlightedButtonIndex:(nullable NSNumber *)highlightedButtonIndex
               backgroundVideoURL:(NSURL *)backgroundVideoURL
                   titleTextColor:(UIColor *)titleTextColor
                subtitleTextColor:(nullable UIColor *)subtitleTextColor {
  LTParameterAssert(highlightedButtonIndex.unsignedIntegerValue < subscriptionDescriptors.count,
                    @"Highlighted button index (%lu) must be lower than the number of buttons "
                    "(%lu)", (unsigned long)highlightedButtonIndex.unsignedIntegerValue,
                    (unsigned long)subscriptionDescriptors.count);
  if (self = [super init]) {
    _titleText = [titleText copy];
    _subtitleText = [subtitleText copy];
    _subscriptionDescriptors = [subscriptionDescriptors copy];
    _preferredSubscriptionIndex = highlightedButtonIndex;
    _backgroundVideoURL = backgroundVideoURL;
    _titleTextColor = titleTextColor;
    _subtitleTextColor = subtitleTextColor ?: titleTextColor;
  }
  return self;
}

- (NSAttributedString *)title {
  return [[NSAttributedString alloc] initWithString:self.titleText attributes:@{
    NSForegroundColorAttributeName: self.titleTextColor,
    NSFontAttributeName: [UIFont spx_fontWithSizeRatio:0.033 minSize:16 maxSize:32
                                                weight:UIFontWeightBold]
  }];
}

- (nullable NSAttributedString *)subtitle {
  if (!self.subtitleText) {
    return nil;
  }

  return [[NSAttributedString alloc] initWithString:self.subtitleText attributes:@{
    NSForegroundColorAttributeName: self.subtitleTextColor,
    NSFontAttributeName: [UIFont spx_standardFontWithSizeRatio:0.019 minSize:13 maxSize:22]
  }];
}

- (void)playVideo {
  self.shouldPlayVideo = YES;
}

- (void)stopVideo {
  self.shouldPlayVideo = NO;
}

@end

NS_ASSUME_NONNULL_END
