// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// Creates a new instance of \c UIImage, all black, with the given \c width and \c height
/// (in points). \c scale is set to the scale factor of the main screen.
UIImage *WFCreateBlankImage(CGFloat width, CGFloat height);

/// Creates a new instance of \c UIImage, filled with \c color, with the given \c width and
/// \c height (in points). \c scale is set to the scale factor of the main screen.
UIImage *WFCreateSolidImage(CGFloat width, CGFloat height, UIColor *color);

/// Returns the color of the pixel at the given coordinates (in points). Raises
/// \c NSInvalidArgumentException if the coordinates are invalid.
UIColor *WFGetPixelColor(UIImage *image, CGFloat x, CGFloat y);

/// Takes snapshot of the \c view and returns it. The returned image \c scale is set to
/// \c contentScaleFactor of the given \c view. Size of the image in points equals to the size of
/// the \c view.
UIImage *WFTakeViewSnapshot(UIView *view);

#ifdef __cplusplus
} // extern "C"
#endif

NS_ASSUME_NONNULL_END
