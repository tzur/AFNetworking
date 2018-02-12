// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSplineRendering.h"

NS_ASSUME_NONNULL_BEGIN

@class DVNPainter, DVNPipelineConfiguration, LTParameterizedObjectType, LTTexture;

@protocol DVNBrushRenderInfoProvider;

/// Protocol to be implemented by objects serving as delegate of \c DVNPainter objects.
@protocol DVNPainterDelegate <DVNSplineRenderingDelegate>

@optional

/// Called just after the given \c painter cleared its canvas with the given \c color.
- (void)painter:(DVNPainter *)painter clearedCanvasWithColor:(LTVector4)color;

@end

/// Object representing a "painter", i.e. an entity with a "canvas" onto which it draws with a
/// "brush" along a "stroke". The canvas is represented by an \c LTTexture, while the brush is
/// described by a \c DVNPipelineConfiguration, and the stroke is incorporated by a sequence of
/// \c LTSplineControlPoint objects. For every stroke, a different brush can be used.
///
/// In a more technical phrasing, objects of this class construct a continuous parameterized object
/// from an iteratively given sequence of control points and consecutively render quadrilateral
/// geometry created from discrete samples of the spline. Refer to the \c DVNSplineRendering
/// protocol for more details. The rendering is performed with a fixed render target, a texture
/// provided upon initialization.
///
/// Objects of this class maintain a weakly held \c id<DVNBrushRenderInfoProvider> object that is
/// used to retrieve the information required for processing the next process sequence. Retrieval
/// occurs at every start of a new process sequence.
///
/// @important: The \c id<DVNBrushRenderInfoProvider> object used by instances of this class must
/// not be deallocated before the last process sequence provided to instances of this class has
/// begun.
@interface DVNPainter : NSObject <DVNSplineRendering>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c canvas, \c brushRenderInfoProvider, and \c delegate. The \c canvas
/// is held strongly, while the \c brushRenderInfoProvider and the \c delegate are held weakly. The
/// \c delegate is provided upon initialization in order to avoid the possibility of partial updates
/// to a delegate which could arise if it was possible to replace the delegate in the middle of a
/// process sequence.
- (instancetype)initWithCanvas:(LTTexture *)canvas
       brushRenderInfoProvider:(id<DVNBrushRenderInfoProvider>)brushRenderInfoProvider
                      delegate:(nullable id<DVNPainterDelegate>)delegate
    NS_DESIGNATED_INITIALIZER;

/// Clears the canvas of this instance with the given \c color, if
/// \c currentlyProcessingContentTouchEventSequence is \c NO. Is silently ignored, otherwise.
- (void)clearCanvasWithColor:(LTVector4)color;

/// Processes the given \c models using the given \c canvas as render targets. The effect of this
/// method is identical to creating a \c DVNPainter and performing process sequences with the
/// information provided by the given \c models.
+ (void)processModels:(NSArray<DVNSplineRenderModel *> *)models
          usingCanvas:(LTTexture *)canvas;

/// Indication whether this instance is currently processing a content touch event sequence. Is set
/// to \c YES at the beginning of a sequence and set to \c NO at the end of the sequence.
/// KVO-compliant.
@property (readonly, nonatomic) BOOL currentlyProcessingContentTouchEventSequence;

/// Delegate to be informed about spline rendering and canvas clearing events.
@property (weak, readonly, nonatomic) id<DVNPainterDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
