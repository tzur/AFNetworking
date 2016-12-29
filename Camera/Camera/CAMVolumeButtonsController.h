// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Controller for responding to presses of the volume buttons. While it's active, pressing the
/// volume buttons on the device will \b not change the volume, and will be intercepted by this
/// class instead.
///
/// @note This object affects global state. Make sure to call \c stop when not needed any more.
@interface CAMVolumeButtonsController : NSObject

/// Initializes with the given target view. \c targetView is used to suppress iOS's built-in
/// volume view, and should be in the view hierarchy and not hidden.
- (instancetype)initWithTargetView:(UIView *)targetView NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Starts intercepting volume button presses. Calling this method while \c started is \c YES has
/// no effect.
- (void)start;

/// Stops intercepting volume button presses, and returns the global state to how it was before
/// calling \c startWithTargetView:. Calling this method while \c started is \c NO has no effect.
- (void)stop;

/// \c YES while the receiver is intercepting volume button presses.
@property (readonly, nonatomic) BOOL started;

/// Hot signal sending \c RACUnits when a volume button is pressed. Only sends while \c started is
/// \c YES.
@property (readonly, nonatomic) RACSignal *volumePressed;

@end

NS_ASSUME_NONNULL_END
