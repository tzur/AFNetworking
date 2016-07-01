// Copyright (c) 2012 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentDisplayManager.h"

@class LTFbo, LTGLContext;

@protocol LTContentLocationProvider;

/// View for displaying rectangular, axis-aligned image content, using OpenGL.
///
/// Uses an \c LTContentLocationProvider responsible for the location of the rectangle bounding the
/// displayed image content.
/// Uses an \c LTPresentationViewDrawDelegate to update the content and control the displayed
/// output (overlays, postprocessing, etc.).
///
/// @note Due to implementation details, the content scale factor of the view must not be changed
/// after the view has been laid out. To achieve this, setting the \c contentScaleFactor is disabled
/// in this view and the \c contentScaleFactor provided by the content location provider is used to
/// permanently set the content scale factor of the view.
@interface LTPresentationView : UIView <LTContentDisplayManager, LTContentRefreshing>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Initializes with the given \c frame, \c context, \c contentTexture, and
/// \c contentLocationProvider. The \c size of the \c contentTexture must equal the \c contentSize
/// of the given \c contentLocationProvider.
///
/// The view displays the content of the \c contentTexture, in the content rectangle provided by the
/// given \c contentLocationProvider. The \c contentLocationProvider is used to retrieve information
/// about the content rectangle and determine the content scale factor to be used by this view. The
/// given \c contentLocationProvider is held weakly.
///
/// @important Objects maintaining instances of this class have to ensure that the \c contentSize
/// provided by the \c contentLocationProvider fits the \c contentTextureSize of this instance when
/// calling the \c replaceContentWith: method.
- (instancetype)initWithFrame:(CGRect)frame context:(LTGLContext *)context
               contentTexture:(LTTexture *)contentTexture
      contentLocationProvider:(id<LTContentLocationProvider>)contentLocationProvider
    NS_DESIGNATED_INITIALIZER;

/// Provider of spatial information of the content rectangle inside of its enclosing view.
@property (readonly, nonatomic) id<LTContentLocationProvider> contentLocationProvider;

@end

#pragma mark -
#pragma mark For Testing
#pragma mark -

@interface LTPresentationView (ForTesting)

/// Binds the given \c fbo, acting as if rendering was performed to a screen framebuffer, and
/// executes the internal rendering pipeline, including the appropriate call to the
/// \c LTPresentationViewDrawDelegate of this instance.
- (void)drawToFbo:(LTFbo *)fbo;

@end
