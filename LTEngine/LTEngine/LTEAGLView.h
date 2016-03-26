// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class LTEAGLView, LTGLContext;

@protocol LTEAGLViewDelegate <NSObject>

/// Called when a new frame needs to be drawn. When called, the OpenGL context of the view is set
/// and the target framebuffer of the view is bound and ready to receive OpenGL draws. \c rect
/// defines the minimal area that has to be redrawn.
///
/// @note \c rect is currently set to the entire bounds of the view, regardless of the specific rect
/// that has been given to \c setNeedsDisplayInRect:. This may be changed in the future and must not
/// be counted on.
- (void)eaglView:(LTEAGLView *)eaglView drawInRect:(CGRect)rect;

@end

/// View drawn by OpenGL ES, displaying the result on screen. The view uses \c CAEAGLLayer as its
/// layer, with a backing store that is allocated with Core Animation to be shared with OpenGL ES.
///
/// The view recreates the underlying storage upon bounds changes. In that case, the delegate will
/// be requested to draw the view contents again to refresh the display.
///
/// The view complies with Apple's OpenGL ES guidelines and avoids performing OpenGL operations when
/// the app is not active, such as creating and deleting objects and requesting the delegate to
/// draw to the view. Once the app becomes active again, a redraw operation will be performed to
/// make sure the display is fresh.
///
/// The view is initialized with a default \c opaque value of \c NO and a \c contentScaleFactor of
/// the screen's native scale. The pixel format of the underlying drawable is
/// \c LTGLPixelFormatRGBA8Unorm with no multisampling and there are no depth or stencil buffers.
///
/// @important if this view is laid out with positive size, zero size and positive size again, the
/// underlying \c CAEAGLLayer will fail allocating the backing storage, which will result in an
/// assert. Currently there is no workaround and such scenarios should be avoided.
///
/// @note the underlying \c CAEAGLLayer will fail allocating the backing storage if the content
/// scale factor of the view is changed after the view has been laid out. To mitigate this, setting
/// the \c contentScaleFactor is disabled in this view, so the view only accepts the \c
/// contentScaleFactor via the initializer.
@interface LTEAGLView : UIView

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Initializes with the given \c frame, \c context and \c contentScaleFactor. OpenGL objects that
/// are required by this view will be created in that context, and the context is guaranteed to be
/// set when the drawing delegate is called.
///
/// The content scale factor is allowed to be set only via the initializer and not via the regular
/// \c setContentScaleFactor: method. See the class documentation for more info.
///
/// @note the initial \c drawableSize of the view will be \c CGSizeZero. Backing store will only be
/// allocated on the first layout.
- (instancetype)initWithFrame:(CGRect)frame context:(LTGLContext *)context
           contentScaleFactor:(CGFloat)contentScaleFactor NS_DESIGNATED_INITIALIZER;

/// OpenGL context used with this view.
@property (readonly, nonatomic) LTGLContext *context;

/// Size of the underlying drawable buffer in pixels. The size of the drawable is equal to
/// \c std::floor(contentScaleFactor * size).
@property (readonly, nonatomic) CGSize drawableSize;

/// Delegate for receiving drawing calls.
@property (weak, nonatomic, nullable) id<LTEAGLViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
