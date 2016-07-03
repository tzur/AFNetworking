// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentLocationProvider.h"
#import "LTContentNavigationManager.h"
#import "LTContentNavigationState.h"

NS_ASSUME_NONNULL_BEGIN

@class LTNavigationView;

@protocol LTInteractionModeProvider;

/// Value class representing the state of an \c LTNavigationView. Can be used to create additional
/// \c LTNavigationView objects with the same zoom, offset, and visible rectangle as another
/// \c LTNavigationView.
@interface LTNavigationViewState : LTContentNavigationState
@end

/// Protocol to be implemented by delegates of \c LTNavigationView objects.
@protocol LTNavigationViewDelegate <NSObject>

/// Called when at least one of the gesture recognizers of the given \c navigationView has been
/// replaced.
- (void)navigationViewReplacedGestureRecognizers:(LTNavigationView *)navigationView;

@end

/// View imitating the behavior of a \c UIScrollView holding arbitrary rectangular, non-rotatable
/// content of a given size. The view provides the information about the spatial location of the
/// content inside the view. The delegate of this class is updated on every update of the spatial
/// location of the content.
///
/// The view provides pan, pinch and double tap gestures that can be used to manipulate the spatial
/// location of the content. The gesture recognizers are not added to this instance but can be added
/// to a suitable view in order to recognize gestures, automatically triggering appropriate
/// navigation events modifying the content rectangle of this instance. Refer to the
/// \c interactionMode property for more information.
///
/// @note The content scale factor of this class equals the one given upon initialization and cannot
///       be updated.
///
/// @important The \c gestureRecognizers property of this instance is an empty array.
@interface LTNavigationView : UIView <LTContentLocationProvider, LTContentNavigationManager>

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
              navigationState:(nullable LTNavigationViewState *)initialNavigationState
    NS_DESIGNATED_INITIALIZER;

/// Informs the instance that the \c interactionMode of the \c interactionModeProvider has been
/// updated.
- (void)interactionModeUpdated;

/// Updates the rectangle visible within the bounds of this instance to be as close as possible to
/// the given \c rect, in point units of the content coordinate system.
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;

/// Size, in integer pixel units of the content coordinate system, of the rectangle managed by this
/// instance.
@property (nonatomic) CGSize contentSize;

/// Object providing the mode defining the currently used interaction of users via gestures and/or
/// touch events.
@property (weak, nonatomic, nullable) id<LTInteractionModeProvider> interactionModeProvider;

/// Delegate of this instance.
@property (weak, nonatomic, nullable) id<LTNavigationViewDelegate> delegate;

/// Recognizer of pinch gestures.
@property (readonly, nonatomic, nullable) UIPanGestureRecognizer *panGestureRecognizer;

/// Recognizer of pinch gestures. Returns \c nil when zooming is disabled.
@property (readonly, nonatomic, nullable) UIPinchGestureRecognizer *pinchGestureRecognizer;

/// Recognizer of double tap gestures.
@property (readonly, nonatomic, nullable) UITapGestureRecognizer *doubleTapGestureRecognizer;

@end

NS_ASSUME_NONNULL_END
