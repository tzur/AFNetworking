// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTViewNavigationState;

/// Protocol which should be implemented by objects providing the location of a rectangle bounding
/// pixel content that can be displayed inside a suitable view. The content rectangle is
/// axis-aligned with the enclosing view.
@protocol LTContentLocationProvider <NSObject>

/// Size, in integer pixel units of the content coordinate system, of the content rectangle managed
/// by this instance.
@property (readonly, nonatomic) CGSize contentSize;

/// Scale factor of the enclosing view.
///
/// @see \c contentScaleFactor property of \c UIView.
@property (readonly, nonatomic) CGFloat contentScaleFactor;

/// Distance, in point units of the screen coordinate system, between the content rectangle and the
/// enclosing view.
@property (readonly, nonatomic) UIEdgeInsets contentInset;

/// Rectangular subregion of the content rectangle, in point units of the content coordinate
/// system, intersecting with the view enclosing the content rectangle.
@property (readonly, nonatomic) CGRect visibleContentRect;

/// Number of floating-point pixel units of the screen coordinate system per pixel unit of the
/// content coordinate system, at the maximum zoom level.
@property (readonly, nonatomic) CGFloat maxZoomScale;

/// Current zoom scale of the content rectangle in relation to the enclosing view. In particular,
/// the zoom scale is defined as the ratio between the width of the enclosing view and the
/// corresponding dimension of the content rectangle.
@property (readonly, nonatomic) CGFloat zoomScale;

/// View that can be used for acquiring touch and gesture locations in content coordinates.
/// For example, the following will return the gesture location in content coordinates (in points):
/// @code
/// [gesture locationInView:ltView.viewForContentCoordinates]
/// @endcode
@property (readonly, nonatomic) UIView *viewForContentCoordinates;

/// Current navigation state of this instance.
@property (readonly, nonatomic) LTViewNavigationState *navigationState;

@end

NS_ASSUME_NONNULL_END
