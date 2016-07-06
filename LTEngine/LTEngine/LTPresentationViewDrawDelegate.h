// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTPresentationView, LTTexture;

/// Protocol which should be implemented by objects producing the image content displayed by an
/// \c LTPresentationView, or overlays above the image content.
@protocol LTPresentationViewDrawDelegate <NSObject>

@optional

/// This method will be used to update the content texture of the given \c presentationView, in the
/// given rectangle.
///
/// @note The viewport for this drawing is mapped to the whole content bounds.
- (void)presentationView:(LTPresentationView *)presentationView updateContentInRect:(CGRect)rect;

/// This method is called after the content is drawn on the given \c presentationView, and can be
/// used for drawing overlays above the content. The given affine transform maps points in
/// floating-point pixel units of the content coordinate system to the corresponding points in point
/// units of the presentation coordinate system.
///
/// @note The viewport for this drawing is mapped to the view bounds.
- (void)presentationView:(LTPresentationView *)presentationView
    drawOverlayAboveContentWithTransform:(CGAffineTransform)transform;

/// Returns a texture that should be displayed by the given \c presentationView instead of the
/// content texture, but using the same modelview and projection matrices to ensure correct
/// alignment, assuming that the alternative texture is of the same size as the content texture.
/// In case this method is implemented but returns \c nil, the content texture will be displayed.
///
/// This method can be used in scenarios where a different texture should be displayed temporarily,
/// for example when comparing to a different image.
- (nullable LTTexture *)alternativeTextureForView:(LTPresentationView *)presentationView;

/// This method will be used to draw the content texture instead of the regular drawing method, for
/// example when the content should be drawn with an applied postprocessing effect.
///
/// @param presentationView the \c LTPresentationView initiating the call.
/// @param contentTexture the content texture to draw.
/// @param visibleContentRect the visible area (in pixels) that should be drawn to the entire
/// framebuffer.
///
/// @return \c YES if the delegate drew the content texture, \c NO in case it didn't (and in this
/// case, the \c LTPresentationView itself will draw the content using the regular drawing method).
- (BOOL)presentationView:(LTPresentationView *)presentationView
    drawProcessedContent:(LTTexture *)contentTexture
  withVisibleContentRect:(CGRect)visibleContentRect;

@end

NS_ASSUME_NONNULL_END
