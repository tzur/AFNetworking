// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTTexture, LTView;

/// This protocol is used to draw the content of the LTView, or overlays above the content.
@protocol LTViewDrawDelegate <NSObject>

@optional

/// This method will be used to update the content texture of the LTView, in the given rectangle.
///
/// @note The viewport for this drawing is mapped to the whole content bounds.
- (void)ltView:(LTView *)view updateContentInRect:(CGRect)rect;

/// This method is called after the content is drawn on the \c LTView, and can be used for drawing
/// overlays above the content. The given affine transform maps the content coordinates to the
/// \c LTView's coordinates according to the current visible content rect.
///
/// @note The viewport for this drawing is mapped to the view bounds.
- (void)ltView:(LTView *)view drawOverlayAboveContentWithTransform:(CGAffineTransform)transform;

/// Returns a texture that will be displayed instead of the content texture, but using the same
/// modelview and projection matrices such that the visible area would match the visible area of the
/// \c LTView's content.
/// In case this method is implemented but returns nil, the content texture will be displayed.
///
/// This method can be used for scenarios where we temporary want to display a different texture,
/// for example when comparing to a different image.
- (LTTexture *)alternativeContentTexture;

/// This method will be used to draw the content texture instead of the regular drawing method, for
/// example when the content should be drawn with an applied postprocessing effect.
///
/// @param view the \c LTView initiating the call.
/// @param contentTexture the content texture to draw.
/// @param visibleContentRect the visible area (in pixels) that should be drawn to the entire
/// framebuffer.
///
/// @return \c YES if the delegate drew the content texture, \c NO in case it didn't (and in this
/// case, the \c LTView itself will draw the content using the regular drawing method).
- (BOOL)ltView:(LTView *)view drawProcessedContent:(LTTexture *)contentTexture
                            withVisibleContentRect:(CGRect)visibleContentRect;

@end

/// Protocol used to get updates on changes of the \c LTView's framebuffer.
@protocol LTViewFramebufferDelegate <NSObject>

@optional

/// Notify the delegate that the \c ltView's framebuffer size has changed.
- (void)ltView:(LTView *)view framebufferChangedToSize:(CGSize)size;

@end
