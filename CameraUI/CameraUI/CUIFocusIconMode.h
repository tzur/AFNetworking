// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// Modes for showing the focus icon.
typedef NS_ENUM(NSUInteger, CUIFocusIconDisplayMode) {
  /// Focus icon is hidden.
  CUIFocusIconDisplayModeHidden,
  /// Focus icon is displayed.
  CUIFocusIconDisplayModeDefinite,
  /// Focus icon is displayed in indefinite mode, suitable for continuous focus.
  CUIFocusIconDisplayModeIndefinite
};

/// Class describing how and where the focus icon should be shown.
@interface CUIFocusIconMode : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a focus icon mode indicating the icon should be hidden. \c position is \c nil.
+ (CUIFocusIconMode *)hiddenFocus;

/// Returns a focus icon mode definite focus at \c position. Position is in view coordinates.
+ (CUIFocusIconMode *)definiteFocusAtPosition:(CGPoint)position;

/// Returns a focus icon mode indefinite focus at \c position. Position is in view coordinates.
+ (CUIFocusIconMode *)indefiniteFocusAtPosition:(CGPoint)position;

/// Mode for showing the focus icon.
@property (readonly, nonatomic) CUIFocusIconDisplayMode mode;

/// The position of the focus mode, or \c nil when in hidden mode.
@property (readonly, nonatomic, nullable) NSValue *position;

@end

NS_ASSUME_NONNULL_END
