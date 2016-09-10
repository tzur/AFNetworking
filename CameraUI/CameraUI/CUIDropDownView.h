// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

@protocol CUIDropDownEntry;

/// \c UIView for a drop down bar.
///
/// This \c UIView receives an \c NSArray of \c CUIDropDownEntry objects, and arranges their
/// \c mainBarItemViews horizontally according to the order in the \c NSArray. The \c width and
/// \c height of each \c mainBarItemView is set according to the height of this \c UIView.
/// The \c mainBarItemViews are distributed in this view with equal spacing, and redistributed
/// whenever the \c hidden property of one of them changes.
///
/// As defined in the \c CUIDropDownEntry protocol, the \c submenuView of each entry must be a
/// subview of its entry's \c mainBarItemView object, and placed and sized relatively to the
/// \c mainBarItemView object.
///
/// This \c UIView changes the visibility of the entries' \c submenuViews as a reaction to taps on
/// the entries' views. Tap on an entry's views will toggle the \c hidden state of its
/// \c submenuView, and will set the \c hidden state of the other entries' \c submenuViews to
/// \c YES.
@interface CUIDropDownView : UIView

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Hides the shown drop down views till next tap on their \c mainBarItemView parent view.
- (void)hideDropDownViews;

/// Array of \c CUIDropDownEntry objects that this view shows. Defaults to an empty array, meaning
/// no buttons are displayed in the bar.
///
/// The \c mainBarItemView views are ordered from left to right according to the order here.
@property (copy, nonatomic) NSArray<id<CUIDropDownEntry>> *entries;

@end

NS_ASSUME_NONNULL_END
