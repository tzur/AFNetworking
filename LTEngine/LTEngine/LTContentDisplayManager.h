// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTImage, LTTexture;

@protocol LTViewDrawDelegate, LTViewFramebufferDelegate;

/// Protocol to be implemented by objects responsible for rendering and displaying rectangular image
/// content.
@protocol LTContentDisplayManager <NSObject>

/// Replaces the content texture with the given \c texture, updating the view's content size to
/// match the new \c texture. If the given \c texture is of the same size as the current texture,
/// the view's navigation state will remain the same, otherwise it will reset to the default
/// navigation state.
- (void)replaceContentWith:(LTTexture *)texture;

/// Indicate that the content in the given rect should be updated.
- (void)setNeedsDisplayContentInRect:(CGRect)rect;

/// Indicates that the whole content should be updated.
- (void)setNeedsDisplayContent;

/// Indicates that the content needs to be presented from scratch.
- (void)setNeedsDisplay;

/// Takes a snapshot of the view.
- (LTImage *)snapshotView;

/// Returns the affine transform mapping the given visible content rectangle to the entire
/// framebuffer.
- (CGAffineTransform)transformForVisibleContentRect:(CGRect)rect;

/// Currently visible rectangle of the content, in floating-point pixel units of the content
/// coordinate system.
@property (readonly, nonatomic) CGRect visibleContentRect;

/// Delegate used to render the image content.
@property (weak, nonatomic, nullable) id<LTViewDrawDelegate> drawDelegate;

/// Delegate informed about framebuffer changes.
@property (weak, nonatomic, nullable) id<LTViewFramebufferDelegate> framebufferDelegate;

/// Size, in pixels, of the framebuffer storing the image content.
@property (readonly, nonatomic) CGSize framebufferSize;

/// Size, in pixels, of the content texture managed by this instance.
@property (readonly, nonatomic) CGSize contentTextureSize;

/// If \c YES, the alpha channel of the content will be used for transparency, and a checkerboard
/// background will be used to visualize the transparent conetnt pixels.
/// Otherwise, the content texture will be opaque.
@property (nonatomic) BOOL contentTransparency;

/// If \c YES, a checkerboard pattern will be drawn on the background, to indicate transparent
/// areas. Otherwise, the background color will be used.
@property (nonatomic) BOOL checkerboardPattern;

/// Background color behind content rectangle. Default value is \c nil in which case the black
/// color is used as background color.
@property (nonatomic, copy, nullable) UIColor *backgroundColor;

@end

NS_ASSUME_NONNULL_END
