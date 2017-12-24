// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@class SPXColorScheme, SPXSubscriptionDescriptor;

#pragma mark -
#pragma mark SPXSubscriptionButtonsPageViewModel protocol
#pragma mark -

/// View-Model for \c SPXSubscriptionButtonsPageView. Represents a single subscription page view
/// with title, subtitle, subscription buttons and the background video that will appear when
/// the page is in focus.
@protocol SPXSubscriptionButtonsPageViewModel <NSObject>

/// Page view styled title.
@property (readonly, nonatomic) NSAttributedString *title;

/// Page view secondary styled title, or \c nil if no subtitle should be shown.
@property (readonly, nonatomic, nullable) NSAttributedString *subtitle;

/// Descriptors of the subscription products to show to the user.
@property (readonly, nonatomic) NSArray<SPXSubscriptionDescriptor *> *subscriptionDescriptors;

/// URL for the subscription screen background video that displayed when the page is in focus.
@property (readonly, nonatomic) NSURL *backgroundVideoURL;

@end

#pragma mark -
#pragma mark SPXSubscriptionButtonsPageViewModel class
#pragma mark -

/// View-Model implementation, receives as input product identifiers, title and subtitle strings
/// and outputs subscription descriptors and attributed strings respectively. Font sizes are
/// determined by the application's window height.
@interface SPXSubscriptionButtonsPageViewModel : NSObject <SPXSubscriptionButtonsPageViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the provided \c titleText, \c subtitleText, \c productIdentifiers and
/// \c backgroundVideoURL. \c colorScheme is pulled from Objection.
- (instancetype)initWithTitleText:(NSString *)titleText
                     subtitleText:(nullable NSString *)subtitleText
               productIdentifiers:(NSArray<NSString *> *)productIdentifiers
               backgroundVideoURL:(NSURL *)backgroundVideoURL;

/// Initializes with the provided \c titleText, \c subtitleText, \c productIdentifiers and
/// \c backgroundVideoURL. \c colorScheme is used to set \c titleTextColor and
/// \c subtitleTextColor to \c textColor.
- (instancetype)initWithTitleText:(NSString *)titleText
                    subtitleText:(nullable NSString *)subtitleText
               productIdentifiers:(NSArray<NSString *> *)productIdentifiers
               backgroundVideoURL:(NSURL *)backgroundVideoURL
                      colorScheme:(SPXColorScheme *)colorScheme;

/// Initializes with the provided \c titleText, \c subtitleText, \c productIdentifiers and
/// \c backgroundVideoURL. \c titleTextColor and \c subtitleTextColor are the colors for
/// \c titleText and \c subtitleText. \c productIdentifiers defines the subscription products that
/// will be offered to the user on the subscribe screen. The order of the array determines the order
/// of the displayed buttons and the order of \c subscriptionDescriptors.
- (instancetype)initWithTitleText:(NSString *)titleText
                    subtitleText:(nullable NSString *)subtitleText
              productIdentifiers:(NSArray<NSString *> *)productIdentifiers
              backgroundVideoURL:(NSURL *)backgroundVideoURL
                  titleTextColor:(UIColor *)titleTextColor
               subtitleTextColor:(UIColor *)subtitleTextColor NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
