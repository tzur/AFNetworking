// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for an entry of a drop-down view. This entry includes a view that shows an item
/// in the main bar view, and the drop-down submenu view for this entry view.
@protocol CUIDropDownEntry <NSObject>

/// \c UIView that shows the item that should appear in the main bar.
@property (readonly, nonatomic) UIView *mainBarItemView;

/// Drop-down menu that shows the subitems for the \c mainBarItemView. This view must be a subview
/// of \c mainBarItemView and placed and sized relatively to the \c mainBarItemView object.
///
/// \c nil value means that that this entry doesn't have a submenu.
@property (readonly, nonatomic, nullable) UIView *submenuView;

/// \c RACSignal that sends a <tt>RACTuple<CUIDropDownEntry, UIView></tt> after \c mainBarItemView
/// or an item from the \c submenuView was tapped. The \c RACTuple contains this \c CUIDropDownEntry
/// object and the \c UIView that was tapped.
///
/// The signal sends on an arbitrary thread, completes when this entry is deallocated, and never
/// errs.
///
/// \c nil value means that \c mainBarItemView doesn't respond to taps.
@property (readonly, nonatomic, nullable) RACSignal *didTapSignal;

@end

NS_ASSUME_NONNULL_END
