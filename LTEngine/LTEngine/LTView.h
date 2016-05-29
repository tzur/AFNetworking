// Copyright (c) 2012 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTViewDelegates.h"
#import "LTViewNavigationMode.h"
#import "LTViewNavigationViewDelegate.h"

@class LTFbo, LTGLContext, LTImage, LTTexture, LTViewNavigationState;

@protocol LTContentLocationManager, LTContentLocationProvider;

/// Model used to initialize an \c LTView with parameters related to rendering and displaying.
@interface LTViewRenderingModel : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a model with the given \c context and \c contentTexture.
+ (instancetype)modelWithContext:(LTGLContext *)context contentTexture:(LTTexture *)contentTexture;

/// OpenGL context to be used by the \c LTView.
@property (readonly, nonatomic) LTGLContext *context;

/// Texture to be displayed by the \c LTView.
@property (readonly, nonatomic) LTTexture *contentTexture;

@end

/// View for displaying rectangular, axis-aligned image content, using OpenGL.
///
/// Uses an \c LTContentLocationManager responsible for the location of the rectangle bounding the
/// displayed image content.
/// Uses an \c LTViewDrawDelegate to update the content and control the displayed output (overlays,
/// postprocessing, etc.).
/// Uses an \c LTViewTouchDelegate to handle touch events received by the view.
@interface LTView : UIView <LTViewNavigationViewDelegate>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Initializes with the given \c frame, \c contentLocationManager and \c renderingModel. The
/// \c size of the \c contentTexture in the given \c renderingModel must be equal to the
/// \c contentSize of the given \c contentLocationManager. The returned view uses the
/// \c contentScaleFactor provided by the given \c contentLocationManager.
///
/// The view displays the content of the \c contentTexture of the given \c renderingModel, in the
/// content rectangle provided by the given \c contentLocationManager. The \c contentLocationManager
/// is used to retrieve information about the content rectangle and is informed about changes of the
/// content texture, following calls to the \c replaceContentWith: method.
- (instancetype)initWithFrame:(CGRect)frame
       contentLocationManager:(id<LTContentLocationManager>)contentLocationManager
               renderingModel:(LTViewRenderingModel *)renderingModel NS_DESIGNATED_INITIALIZER;

/// Replaces the content texture with the given \c texture, updating the view's content size to
/// match the new \c texture. If the given \c texture is of the same size as the current texture,
/// the view's navigation state will remain the same, otherwise it will reset to the default
/// navigation state.
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

/// Returns the affine transform mapping the given visible content rectangle to the entire
/// framebuffer.
- (CGAffineTransform)transformForVisibleContentRect:(CGRect)rect;

/// Currently visible rectangle of the content, in floating-point pixel units of the content
/// coordinate system.
@property (readonly, nonatomic) CGRect visibleContentRect;

/// Provider of information about the location of the content rectangle.
@property (readonly, nonatomic) id<LTContentLocationProvider> contentLocationProvider;

/// This delegate will be used to update the \c LTView's content.
@property (weak, nonatomic) id<LTViewDrawDelegate> drawDelegate;

/// Touch events will be forwarded to this delegate.
@property (weak, nonatomic) id<LTViewTouchDelegate> touchDelegate;

/// Navigation events from \c LTViewNavigationView will be forwarded to this delegate.
///
/// @see LTViewNavigationView.
@property (weak, nonatomic) id<LTViewNavigationDelegate> navigationDelegate;

/// Delegate informed about framebuffer changes.
@property (weak, nonatomic) id<LTViewFramebufferDelegate> framebufferDelegate;

/// Size of the \c LTView's framebuffer, in pixels.
@property (readonly, nonatomic) CGSize framebufferSize;

/// View to which gesture recognizers should be attached.
@property (readonly, nonatomic) UIView *gestureView;

/// If \c YES, the alpha channel of the content will be used for transparency, and a checkerboard
/// background will be used to visualize the transparent conetnt pixels.
/// Otherwise, the content texture will be opaque.
@property (nonatomic) BOOL contentTransparency;

/// If \c YES, a checkerboard pattern will be drawn on the background, to indicate transparent
/// areas. Otherwise, the background color will be used.
@property (nonatomic) BOOL checkerboardPattern;

/// If \c YES, the view will forward touch events to the \c touchDelegate (assuming the navigation
/// mode permits).
@property (nonatomic) BOOL forwardTouchesToDelegate;

/// Controls which navigation gestures are currently enabled, and the navigation behavior of the
/// view, if mode other than \c LTViewNavigationNone or \c LTViewNavigationTwoFingers, touch events
/// will not be forwarded to the \c touchDelegate.
@property (nonatomic) LTViewNavigationMode navigationMode;

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

@end
