// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@class SPXColorScheme;

#pragma mark -
#pragma mark SPXSubscriptionVideoPageViewModel protocol
#pragma mark -

/// View-Model for \c SPXSubscriptionVideoPageView. Represents a single subscription page view
/// with video, title and subtitle.
@protocol SPXSubscriptionVideoPageViewModel <NSObject>

/// URL for the page video.
@property (readonly, nonatomic) NSURL *videoURL;

/// Page view styled title.
@property (readonly, nonatomic) NSAttributedString *title;

/// Page view secondary styled title. If \c nil no subtitle is shown.
@property (readonly, nonatomic, nullable) NSAttributedString *subtitle;

/// Video's border color.
@property (readonly, nonatomic, nullable) UIColor *videoBorderColor;

@end

#pragma mark -
#pragma mark SPXSubscriptionVideoPageViewModel class
#pragma mark -

/// View-Model implementation, receives as inputs the page video URL, title and subtitle strings and
/// outputs the attributed strings respectively. Font sizes are determined by the screen height.
@interface SPXSubscriptionVideoPageViewModel : NSObject <SPXSubscriptionVideoPageViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the provided \c videoURL, \c titleText and \c subtitleText. \c colorScheme is
/// pulled from Objection.
- (instancetype)initWithVideoURL:(NSURL *)videoURL titleText:(NSString *)titleText
                    subtitleText:(nullable NSString *)subtitleText;

/// Initializes with the provided \c videoURL, \c titleText and \c subtitleText. \c colorScheme is
/// used to set the \c titleTextColor and \c subtitleTextColor to \c textColor.
- (instancetype)initWithVideoURL:(NSURL *)videoURL titleText:(NSString *)titleText
                    subtitleText:(nullable NSString *)subtitleText
                     colorScheme:(SPXColorScheme *)colorScheme;

/// Initializes with the provided \c videoURL, \c titleText and \c subtitleText. \c titleTextColor
/// and \c subtitleTextColor are the colors for \c titleText and \c subtitleText.
- (instancetype)initWithVideoURL:(NSURL *)videoURL titleText:(NSString *)titleText
                    subtitleText:(nullable NSString *)subtitleText
                videoBorderColor:(nullable UIColor *)videoBorderColor
                  titleTextColor:(UIColor *)titleTextColor
               subtitleTextColor:(UIColor *)subtitleTextColor NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
