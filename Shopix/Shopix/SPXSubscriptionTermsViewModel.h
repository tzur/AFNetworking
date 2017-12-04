// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark SPXSubscriptionTermsViewModel protocol
#pragma mark -

/// View-Model for \c SPXSubscriptionTermsView.
@protocol SPXSubscriptionTermsViewModel <NSObject>

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

@end

NS_ASSUME_NONNULL_END
