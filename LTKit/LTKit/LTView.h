// Copyright (c) 2012 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTViewDelegates.h"
#import "LTViewNavigationMode.h"

@class LTFbo, LTGLContext, LTImage, LTTexture, LTViewNavigationState;

/// The \c LTView class is used for displaying zoomable and scrollable openGL output.
///
/// Uses an \c LTViewDrawDelegate to update the content and control the displayed output (overlays,
/// postprocessing, etc.).
/// Uses an \c LTViewTouchDelegate to handle touch events received by the view.
///
/// @note The \c setupWithContext: method must be called for the view to start displaying the openGL
/// content.
@interface LTView : UIView

/// Setup the LTView by providing an \c LTGLCcontext, a content texture to use for content, and an
/// \c LTViewNavigationState with the initial state of the view (zoom, offset, etc.). In case a
/// \c nil state is given, the \c LTView will automatically zoom out such that the whole content is
/// visible.
///
/// @note Calling this method when the \c LTView was already set (and before \c teardown was called)
/// will do nothing.
- (void)setupWithContext:(LTGLContext *)context contentTexture:(LTTexture *)texture
                   state:(LTViewNavigationState *)state;

/// Cleanup resources, reducing the memory signature of the \c LTView while it is not used.
/// \c setupWithContext: must be called before the \c LTView can be used again.
///
/// @note Calling this method after before the \c LTView was set (or after a previous \c teardown)
/// will do nothing.
- (void)teardown;

/// Replaces the content texture with the given texture, updating the view's content size to match
/// the new texture. This operation resets the navgiation state of the view to the default one.
- (void)replaceContentWith:(LTTexture *)texture;

/// Temporary detaches the from the content texture. This should be called when going to the
/// background, to reduce the memory signature of the \c LTView, and releases the Fbo connected to
/// the content texture.
/// \c reattachFbo must be called when returning to foreground in order to work with the LTView.
- (void)detachFbo;

/// Reattaches to the content texture. This should be called if \c detachFbo was called, or if the
/// content texture was released and replaced.
- (void)reattachFbo;

/// Indicate that the content in the given rect should be updated.
- (void)setNeedsDisplayContentInRect:(CGRect)rect;

/// Indicates that the whole content should be updated.
- (void)setNeedsDisplayContent;

/// Takes a snapshot of the view.
- (LTImage *)snapshotView;

/// Notifies the view that it is about to be rotated to the given orientation due to an interface
/// orientation change.
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation;

/// Notifies the view that the rotation animation is about to start. This is called after the layout
/// has been updated to reflect the new orientation.
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation;

/// Returns the affine transform mapping the given visible content rectangle to the entire
/// framebuffer.
- (CGAffineTransform)transformForVisibleContentRect:(CGRect)rect;

/// This delegate will be used to update the \c LTView's content.
@property (weak, nonatomic) id<LTViewDrawDelegate> drawDelegate;

/// Touch events will be forwarded to this delegate.
@property (weak, nonatomic) id<LTViewTouchDelegate> touchDelegate;

/// Navigation events from \c LTViewNavigationView will be forwarded to this delegate.
///
/// @see LTViewNavigationView.
@property (weak, nonatomic) id<LTViewNavigationDelegate> navigationDelegate;

/// Size of the \c LTView's content, in pixels.
@property (readonly, nonatomic) CGSize contentSize;

/// Size of the \c LTView's framebuffer, in pixels.
@property (readonly, nonatomic) CGSize framebufferSize;

/// If \c YES, the alpha channel of the content will be used for transparency, and a checkerboard
/// background will be used to visualize the transparent conetnt pixels.
/// Otherwise, the content texture will be opaque.
@property (nonatomic) BOOL contentTransparency;

/// If \c YES, a checkerboard pattern will be drawn on the background, to indicate transparent
/// areas. Otherwise, the background color will be used.
@property (nonatomic) BOOL checkerboardPattern;

/// If \c YES, the view will forward touch events to the touchDelegate.
@property (nonatomic) BOOL forwardTouchesToDelegate;

/// Controls which navigation gestures are currently enabled, and the navigation behavior of the
/// view.
@property (nonatomic) LTViewNavigationMode navigationMode;

/// The distance between the content and the enclosing view.
@property (nonatomic) UIEdgeInsets contentInset;

/// The ratio of device screen pixels per content pixel at the maximal zoom level. Default is \c 16.
@property (nonatomic) CGFloat maxZoomScale;

/// The factor applied to the calculated minZoomScale (fits the image exactly inside the view).
/// Setting this to values smaller than 1 will make the image smaller than the \c LTView when fully
/// zoomed out, and vice versa. Default is \c 0, meaning the value is ignored.
@property (nonatomic) CGFloat minZoomScaleFactor;

// The zoom factor of the double tap gesture between the different levels. Double tapping will zoom
// to a scale of this factor multiplied by the previous zoom scale (except when in the maximal level
// which will zoom out to the minimal zoom scale). Default is \c 3.
@property (nonatomic) CGFloat doubleTapZoomFactor;

// Number of different levels of zoom that the double tap switches between. Default is \c 3.
@property (nonatomic) NSUInteger doubleTapLevels;

/// Returns the current navigation state of the view, see \c LTViewNavigationState.
@property (readonly, nonatomic) LTViewNavigationState *navigationState;

/// Returns the current visible rectangle of the content, in pixels.
@property (readonly, nonatomic) CGRect visibleContentRect;

/// Returns the current zoom scale of the \c LTView.
@property (readonly, nonatomic) CGFloat zoomScale;

/// A view that can be used for acquiring touch and gesture locations in content coordinates.
/// For example, the following will return the gesture location in content coordinates (in points):
/// @code
/// [gesture locationInView:ltView.viewForContentCoordinates]
/// @endcode
@property (readonly, nonatomic) UIView *viewForContentCoordinates;

@end

#pragma mark -
#pragma mark For Testing
#pragma mark -

@interface LTView (ForTesting)

/// Renders the LTView at its current state into the given Fbo, acting as if rendering to a screen
/// framebuffer.
- (void)drawToFbo:(LTFbo *)fbo;

/// Simulates touches on the LTView, for testing events forwarding to the touch delegate.
/// @note This does not simulate an actual touch, and an empty set of touches will be passed to the
/// delegate, with a \c nil \c UIEvent.
- (void)simulateTouchesOfPhase:(UITouchPhase)phase;

/// Forces the underlying \c GLKView to allocate its framebuffer, since it doesn't happen until the
/// view is connected to a window and needs to be drawn.
- (void)forceGLKViewFramebufferAllocation;

@end
