// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@class SPXColorScheme, SPXSubscriptionDescriptor;

#pragma mark -
#pragma mark SPXSubscriptionButtonsPageViewModel protocol
#pragma mark -

/// View-Model for \c SPXSubscriptionButtonsPageView. Represents a single subscription page view
/// with title, subtitle, subscription buttons and background video where one of the buttons can be
/// highlighted.
@protocol SPXSubscriptionButtonsPageViewModel <NSObject>

/// Page view styled title.
@property (readonly, nonatomic) NSAttributedString *title;

/// Page view secondary styled title, or \c nil if no subtitle should be shown.
@property (readonly, nonatomic, nullable) NSAttributedString *subtitle;

/// Descriptors of the subscription products to show to the user.
@property (readonly, nonatomic) NSArray<SPXSubscriptionDescriptor *> *subscriptionDescriptors;

/// Preferred subscription product index. The button for this subscription product will be
/// unique, or \c nil for no preferred product. Must be in the range
/// <tt>[0, subscriptionDescriptors.count - 1]</tt>.
@property (readonly, nonatomic, nullable) NSNumber *preferredSubscriptionIndex;

/// URL for the subscription screen background video that displayed when the page is in focus.
@property (readonly, nonatomic) NSURL *backgroundVideoURL;

/// Indicates if the page's background video should be playing. KVO compliant.
@property (readonly, nonatomic) BOOL shouldPlayVideo;

/// Starts the video playback in loop.
- (void)playVideo;

/// Stops the video playback.
- (void)stopVideo;

@end

#pragma mark -
#pragma mark SPXSubscriptionButtonsPageViewModel class
#pragma mark -

/// View-Model implementation, receives as input subscription descriptors, title and subtitle
/// strings and outputs subscription descriptors and attributed strings respectively. Font sizes are
/// determined by the application's window height.
@interface SPXSubscriptionButtonsPageViewModel : NSObject <SPXSubscriptionButtonsPageViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c titleText, \c subtitleText, \c subscriptionDescriptors,
/// \c highlightedButtonIndex and \c backgroundVideoURL. \c colorScheme is pulled from Objection.
- (instancetype)initWithTitleText:(NSString *)titleText
                     subtitleText:(nullable NSString *)subtitleText
          subscriptionDescriptors:(NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors
           highlightedButtonIndex:(nullable NSNumber *)highlightedButtonIndex
               backgroundVideoURL:(NSURL *)backgroundVideoURL;

/// Initializes with the given \c titleText, \c subtitleText, \c subscriptionDescriptors,
/// \c highlightedButtonIndex and \c backgroundVideoURL. \c colorScheme is used to set
/// \c titleTextColor and \c subtitleTextColor to \c textColor.
- (instancetype)initWithTitleText:(NSString *)titleText
                     subtitleText:(nullable NSString *)subtitleText
          subscriptionDescriptors:(NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors
           highlightedButtonIndex:(nullable NSNumber *)highlightedButtonIndex
               backgroundVideoURL:(NSURL *)backgroundVideoURL
                      colorScheme:(SPXColorScheme *)colorScheme;

/// Initializes with the given \c titleText, \c subtitleText that will be used as the page's
/// \c title and subtitle respectively. \c subscriptionDescriptors defines the subscription products
/// that will be offered to the user on the subscribe screen, the order of the array determines the
/// order of the displayed buttons, if \c subscriptionDescriptors is empty no buttons will be
/// presented. \c highlightedButtonIndex is used as the page's \c preferredSubscriptionIndex so the
/// preferred button will be highlighted, must be in range
/// <tt>[0, productIdentifiers.count - 1]</tt>. \c backgroundVideoURL is the URL the page's
/// background video. \c titleTextColor and \c subtitleTextColor are the colors for \c titleText
/// and \c subtitleText respectively.
- (instancetype)initWithTitleText:(NSString *)titleText
                     subtitleText:(nullable NSString *)subtitleText
          subscriptionDescriptors:(NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors
           highlightedButtonIndex:(nullable NSNumber *)highlightedButtonIndex
               backgroundVideoURL:(NSURL *)backgroundVideoURL
                   titleTextColor:(UIColor *)titleTextColor
                subtitleTextColor:(nullable UIColor *)subtitleTextColor NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
