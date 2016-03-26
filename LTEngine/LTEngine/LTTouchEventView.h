// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@protocol LTTouchEventDelegate;

/// View converting incoming \c UITouch objects to \c LTTouchEvent objects and passing them on to
/// its delegate.
@interface LTTouchEventView : UIView

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

/// Initializes with the given \c frame and the given \c delegate to which converted touch events
/// are delegated. The given \c delegate is held weakly.
- (instancetype)initWithFrame:(CGRect)frame
                     delegate:(id<LTTouchEventDelegate>)delegate NS_DESIGNATED_INITIALIZER;

/// Delegate to which converted touch events are delegated.
@property (weak, readonly, nonatomic) id<LTTouchEventDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
