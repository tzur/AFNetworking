// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentCoordinateConverter.h"
#import "LTContentDisplayManager.h"
#import "LTContentInteraction.h"
#import "LTContentLocationProvider.h"
#import "LTContentNavigationManager.h"

NS_ASSUME_NONNULL_BEGIN

@class LTContentNavigationState, LTGLContext;

/// View for displaying rectangular, axis-aligned, zoomable image content, using OpenGL.
/// The view is initialized with an OpenGL context, and, optionally, a frame, a content scale
/// factor, a texture constituting the content to be displayed, and a certain navigation state.
///
/// The view implements several protocols via which the displayed image content is controlled:
/// The \c LTContentDisplayManager is responsible for the displayed image content.
/// The location of the content rectangle (and thus, the location of the displayed image content)
/// can be controlled both programmatically and via gestures (refer to the
/// \c LTContentInteractionManager and \c LTContentNavigationManager protocols for more
/// information). The view is responsible for managing which gestures should be allowed to modify
/// the location of the content rectangle. In addition, it handles the forwarding of touch events
/// occurring on itself and allows attaching/detaching custom gesture recognizers to itself. It also
/// provides information about the current location of the content rectangle and manages the
/// rendering of the displayed image content.
///
/// @important The functionality of adding gesture recognizers to this view via the
///            \c addGestureRecognizer method or the \c gestureRecognizers property is disabled.
///            Analogously, removing gesture recognizers via the \c removeGestureRecognizer method
///            or the \c gestureRecognizers property is disabled as well. In order to add custom
///            gesture recognizers, refer to the API of the \c LTContentInteractionManager protocol.
@interface LTContentView : UIView <LTContentCoordinateConverter, LTContentDisplayManager,
    LTContentInteractionManager, LTContentLocationProvider, LTContentNavigationManager,
    LTContentRefreshing>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)decoder NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

/// Initializes with the given \c context. Is identical to calling:
///
/// @code
///   [initWithContext:context contentTexture:nil navigationState:nil]
/// @endcode
- (instancetype)initWithContext:(LTGLContext *)context;

/// Initializes with the given \c context, \c contentTexture, and \c navigationState. Is identical
/// to calling:
///
/// @code
///   [initWithFrame:CGRectZero contentScaleFactor:[UIScreen mainScreen].nativeScale
///    context:context contentTexture:contentTexture navigationState:navigationState]
/// @endcode
- (instancetype)initWithContext:(LTGLContext *)context
                 contentTexture:(nullable LTTexture *)contentTexture
                navigationState:(nullable LTContentNavigationState *)navigationState;

/// Initializes with the given \c frame, \c contentScaleFactor, \c context, \c contentTexture and
/// \c navigationState. If the given \c contextTexture is \c nil, the returned instance uses a clear
/// dummy texture of size <tt>1 x 1</tt>. If the given \c navigationState is \c nil, the returned
/// instance uses the default navigation state in which the content is aspect-fit. The given
/// \c contentScaleFactor must be positive. In a standard use case, the given \c contentScaleFactor
/// equals <tt>[UIScreen mainScreen].nativeScale</tt>.
- (instancetype)initWithFrame:(CGRect)frame contentScaleFactor:(CGFloat)contentScaleFactor
                      context:(LTGLContext *)context
               contentTexture:(nullable LTTexture *)contentTexture
              navigationState:(nullable LTContentNavigationState *)navigationState
    NS_DESIGNATED_INITIALIZER;

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer NS_UNAVAILABLE;

- (void)setGestureRecognizers:(nullable NSArray<UIGestureRecognizer *> *)recognizers NS_UNAVAILABLE;

- (void)removeGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
