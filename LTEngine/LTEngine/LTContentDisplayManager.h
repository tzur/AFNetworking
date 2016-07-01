// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTImage, LTTexture;

@protocol LTPresentationViewDrawDelegate, LTPresentationViewFramebufferDelegate;

/// Protocol to be implemented by objects responsible for triggering the refreshing of displayed
/// rectangular image content.
@protocol LTContentRefreshing <NSObject>

/// Triggers an update of the content in the given \c rect. Specifically, after calling this method,
/// the \c drawDelegate of the used \c LTContentDisplayManager is requested to update the content in
/// the given \c rect. The update request is performed immediately following the next trigger event
/// of the display link, ensuring that the update exploits the next frame as much as possible.
- (void)setNeedsDisplayContentInRect:(CGRect)rect;

/// Triggers an update of the entire content. Identical to calling
///
/// @code
/// [setNeedsDisplayContentInRect:contentSize]
/// @endcode
///
/// where \c contentSize is the size of the content rectangle.
- (void)setNeedsDisplayContent;

/// Triggers a presentation of the content.
///
/// @important In contrast to the \c setNeedsDisplayContentInRect: and \c setNeedsDisplayContent
///            methods, no updates of the content are performed but the content is presented in its
///            current state.
- (void)setNeedsDisplay;

@end

/// Protocol to be implemented by objects responsible for rendering and displaying rectangular image
/// content.
@protocol LTContentDisplayManager <NSObject>

/// Replaces the content texture with the given \c texture, updating the view's content size to
/// match the new \c texture. If the given \c texture is of the same size as the current texture,
/// the view's navigation state will remain the same, otherwise it will reset to the default
/// navigation state.
- (void)replaceContentWith:(LTTexture *)texture;

/// Takes a snapshot of the view.
- (LTImage *)snapshotView;

/// Delegate used to render the image content.
@property (weak, nonatomic, nullable) id<LTPresentationViewDrawDelegate> drawDelegate;

/// Delegate informed about framebuffer size changes.
@property (weak, nonatomic, nullable) id<LTPresentationViewFramebufferDelegate> framebufferDelegate;

/// Size, in pixels, of the framebuffer storing the image content.
@property (readonly, nonatomic) CGSize framebufferSize;

/// Size, in pixels, of the content texture managed by this instance.
@property (readonly, nonatomic) CGSize contentTextureSize;

/// If \c YES, the alpha channel of the content will be used for transparency. The content texture
/// is assumed to be in premultiplied format. If \c NO and the alpha channel of the content texture
/// is not \c 1, the result is undefined.
@property (nonatomic) BOOL contentTransparency;

/// If \c YES, a checkerboard pattern will be drawn on the background, to indicate transparent
/// areas. Otherwise, the background color will be used. Irrelevant if \c contentTransparency is
/// \c NO.
@property (nonatomic) BOOL checkerboardPattern;

/// Background color behind the displayed content rectangle. Default value is
/// <tt>UIColor blackColor</tt>. The opacity of any used background color is \c 1, independent of
/// the opacity value of provided colors. Setting this property to \c nil results in usage of
/// default value.
@property (strong, nonatomic, nullable) UIColor *backgroundColor;

@end

NS_ASSUME_NONNULL_END
