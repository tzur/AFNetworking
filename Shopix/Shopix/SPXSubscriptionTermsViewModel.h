// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@class SPXSubscriptionDescriptor;

#pragma mark -
#pragma mark SPXSubscriptionTermsViewModel protocol
#pragma mark -

/// View-Model for \c SPXSubscriptionTermsView.
@protocol SPXSubscriptionTermsViewModel <NSObject>

/// Updates the \c termsGistText according to the given \c subscriptionDescriptors. If the array
/// contains a yearly/bi-yearly subscription the text "* Billed in one payment of
/// <yearly subscription price>" will be appended as well. If \c subscriptionDescriptors is \c nil
/// the terms gist text is set to \c nil.
- (void)updateTermsGistWithSubscriptions:
    (nullable NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors;

/// Optional attributed string that is presented before the terms text, used for a dynamic text such
/// as terms that depends on a specific subscription. KVO Complaint.
@property (readonly, nonatomic, nullable) NSAttributedString *termsGistText;

/// Attributed string for the terms overview.
@property (readonly, nonatomic) NSAttributedString *termsText;

/// Attributed string for the terms of use link.
@property (readonly, nonatomic) NSAttributedString *termsOfUseLink;

/// Attributed string for the privacy policy of use link.
@property (readonly, nonatomic) NSAttributedString *privacyPolicyLink;

@end

#pragma mark -
#pragma mark SPXSubscriptionTermsViewModel class
#pragma mark -

/// An \c SPXSubscriptionTermsViewModel implementation for receiving the terms string and URLs as
/// input and outputs attributed strings respectively.
@interface SPXSubscriptionTermsViewModel : NSObject <SPXSubscriptionTermsViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the default terms content. The full subscription terms-of-use and
/// privacy-policy URLs are set by \c fullTermsURL and \c privacyPolicyURL. \c termsTextColor and
/// \c linksColor are set to the default colors.
- (instancetype)initWithFullTerms:(NSURL *)fullTermsURL privacyPolicy:(NSURL *)privacyPolicyURL;

/// Initializes with \c termsOverview, with the full subscription terms-of-use and privacy-policy
/// URLs are set by \c fullTermsURL and \c privacyPolicyURL. \c termsTextColor and \c linksColor
/// are set to the default colors.
- (instancetype)initWithTermsOverview:(NSString *)termsOverview
                            fullTerms:(NSURL *)fullTermsURL
                        privacyPolicy:(NSURL *)privacyPolicyURL;

/// Initializes with \c termsOverview, with the full subscription terms-of-use and privacy-policy
/// URLs are set by \c fullTermsURL and \c privacyPolicyURL. \c termsOverviewColor is the color for
/// \c termsText and \c linksColor is the color for \c termsOfUseLink and \c privacyPolicyLink.
- (instancetype)initWithTermsOverview:(NSString *)termsOverview
                            fullTerms:(NSURL *)fullTermsURL
                        privacyPolicy:(NSURL *)privacyPolicyURL
                       termsTextColor:(UIColor *)termsTextColor
                           linksColor:(UIColor *)linksColor NS_DESIGNATED_INITIALIZER;

/// Default terms overview string.
@property (class, readonly, nonatomic) NSString *defaultTermsOverview;

/// Default note used to clarify the exact nature of the billing for subscription products for which
/// the retail price is different than the presented price. For example, a subscription with yearly
/// billing period that its price is divided by 12 and only the relative price per month is
/// presented to the user.
@property (class, readonly, nonatomic) NSString *defaultTermsGist;

/// Same as \c defaultTermsGist appended with the localized price.
@property (class, readonly, nonatomic) NSString *defaultTermsGistWithPrice;

@end

NS_ASSUME_NONNULL_END
