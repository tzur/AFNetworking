// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// Layout view for terms text, terms of use link and privacy policy link.
@interface SPXSubscriptionTermsView : UIView

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Initializes with the given view model properties, \c termsText is the terms overview,
/// \c termsOfUseLink and \c privacyPolicyLink the links for the full terms of use and privacy
/// policy documents.
- (instancetype)initWithTermsText:(NSAttributedString *)termsText
                   termsOfUseLink:(NSAttributedString *)termsOfUseLink
                privacyPolicyLink:(NSAttributedString *)privacyPolicyLink NS_DESIGNATED_INITIALIZER;

/// The inset of the terms text. Defaults to \c UIEdgeInsetsZero.
@property (nonatomic) UIEdgeInsets termsTextContainerInset;

/// Optional text that is presented before the terms overview. Defaults to \c nil.
@property (strong, nonatomic, nullable) NSAttributedString *termsGistText;

@end

NS_ASSUME_NONNULL_END
