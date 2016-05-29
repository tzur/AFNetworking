// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTViewNavigationMode.h"

#import "LTContentLocationManager.h"

@protocol LTViewNavigationViewDelegate;

/// Value class representing the state of an \c LTViewNavigationView. Can be used to create
/// additional \c LTViewNavigationView objects with the same zoom, offset, and visible rectangle as
/// another \c LTViewNavigationView.
@interface LTViewNavigationState : NSObject
@end

/// View imitating the behavior of a \c UIScrollView holding arbitrary rectangular, non-rotatable
/// content of a given size. The view provides the information about the spatial location of the
/// content inside the view. The delegate of this class is updated on every update of the spatial
/// location of the content.
///
/// The view recognizes pan, pinch and double tap gestures used to manipulate the spatial location
/// of the content. Refer to the \c navigationMode property for more information.
///
/// @note The content scale factor of this class equals the one given upon initialization and cannot
///       be updated.
@interface LTViewNavigationView : UIView <LTContentLocationManager>

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Initializes with the given \c frame, \c contentSize, \c contentScaleFactor and
/// \c initialNavigationState. The given \c contentSize is the size, in units of the pixel
/// coordinate system, of the rectangular, non-rotatable content managed by this view. If the given
/// \c initialNavigationState is \c nil, the returned view uses the default navigation state in
/// which the content is aspect-fit. The given \c contentScaleFactor must be positive. In a standard
/// use case, the given \c contentScaleFactor equals <tt>[UIScreen mainScreen].nativeScale</tt>.
- (instancetype)initWithFrame:(CGRect)frame
                  contentSize:(CGSize)contentSize
           contentScaleFactor:(CGFloat)contentScaleFactor
              navigationState:(LTViewNavigationState *)initialNavigationState
    NS_DESIGNATED_INITIALIZER;

/// Navigates to the given navigation \c state. The \c state must have been extracted from an
/// \c LTViewNavigationView with the same properties as this instance, except for properties held by
/// the given navigation \c state.
- (void)navigateToState:(LTViewNavigationState *)state;

/// Updates the rectangle visible within the bounds of this instance to be as close as possible to
/// the given \c rect, in point units of the content coordinate system, of the content.
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;

/// The delegate will be updated whenever the visible content rectangle is changed.
@property (weak, nonatomic) id<LTViewNavigationViewDelegate> delegate;

/// Gesture recognizers provided by this view. The gesture recognizers are not added to this
/// instance but can be added to a suitable view in order to recognize gestures, automatically
/// triggering appropriate navigation events modifying the content rectangle of this instance.
///
/// @important The \c gestureRecognizers property of this instance is an empty array.
@property (readonly, nonatomic) NSArray<UIGestureRecognizer *> *navigationGestureRecognizers;

@end
