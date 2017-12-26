// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dana Feischer.

NS_ASSUME_NONNULL_BEGIN

@class MASViewAttribute;

/// Category which wraps Masonry's safe area methods. The category's methods return Masonary's safe
/// area \c MASViewAttribute if available, otherwise they return a \c MASViewAttribute of the
/// receiver with the corresponding \c NSLayoutAttribute.
@interface UIView (MasonrySafeAreaLayoutGuide)

/// Returns the \c mas_safeAreaLayoutGuide of the view if exists and \c MASViewAttribute of the
/// receiver with \c NSLayoutAttributeNotAnAttribute otherwise, which equivalent to the view's first
/// matched layout attribute when applying the constraints.
@property (readonly, nonatomic) MASViewAttribute *wf_safeArea;

/// Returns the \c mas_safeAreaLayoutGuideLeft of the view if exists and \c MASViewAttribute of the
/// receiver with \c NSLayoutAttributeLeft otherwise.
@property (readonly, nonatomic) MASViewAttribute *wf_safeAreaLeft;

/// Returns the \c mas_safeAreaLayoutGuideRight of the view if exists and \c MASViewAttribute of the
/// receiver with \c NSLayoutAttributeRight otherwise.
@property (readonly, nonatomic) MASViewAttribute *wf_safeAreaRight;

/// Returns the \c mas_safeAreaLayoutGuideTop of the view if exists and \c MASViewAttribute of the
/// receiver with \c NSLayoutAttributeTop otherwise.
@property (readonly, nonatomic) MASViewAttribute *wf_safeAreaTop;

/// Returns the \c mas_safeAreaLayoutGuideBottom of the view if exists and \c MASViewAttribute of
/// the receiver with \c NSLayoutAttributeBottom otherwise.
@property (readonly, nonatomic) MASViewAttribute *wf_safeAreaBottom;

/// Returns the \c mas_safeAreaLayoutGuideHeight of the view if exists and \c MASViewAttribute of
/// the receiver with \c NSLayoutAttributeHeight otherwise.
@property (readonly, nonatomic) MASViewAttribute *wf_safeAreaHeight;

/// Returns the \c mas_safeAreaLayoutGuideWidth of the view if exists and \c MASViewAttribute of the
/// receiver with \c NSLayoutAttributeWidth otherwise.
@property (readonly, nonatomic) MASViewAttribute *wf_safeAreaWidth;

@end

NS_ASSUME_NONNULL_END
