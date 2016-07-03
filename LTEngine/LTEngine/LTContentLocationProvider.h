// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Protocol which should be implemented by objects providing the location of a rectangle bounding
/// pixel content that can be displayed inside a suitable view. The content rectangle is
/// axis-aligned with the enclosing view.
@protocol LTContentLocationProvider <NSObject>

/// Size, in integer pixel units of the content coordinate system, of the rectangle managed by this
/// instance.
@property (readonly, nonatomic) CGSize contentSize;

/// Scale factor of the enclosing view.
///
/// @see \c contentScaleFactor property of \c UIView.
@property (readonly, nonatomic) CGFloat contentScaleFactor;

/// Distance, in point units of the screen coordinate system, between the content rectangle and the
/// enclosing view.
@property (readonly, nonatomic) UIEdgeInsets contentInset;

/// Rectangular subregion, in floating-point pixel units of the content coordinate system, of the
/// content rectangle intersecting with the view enclosing the content rectangle.
@property (readonly, nonatomic) CGRect visibleContentRect;

/// Number of floating-point pixel units of the screen coordinate system per pixel unit of the
/// content coordinate system, at the maximum zoom level.
@property (readonly, nonatomic) CGFloat maxZoomScale;

/// Current zoom scale of the content rectangle in relation to the enclosing view. In particular,
/// the zoom scale is defined as the ratio between the width of the enclosing view and the
/// corresponding dimension of the content rectangle.
@property (readonly, nonatomic) CGFloat zoomScale;

@end

NS_ASSUME_NONNULL_END
