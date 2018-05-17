// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSplineRendering.h"

NS_ASSUME_NONNULL_BEGIN

@class DVNBrushRenderModel, DVNBrushStrokeSpecification, DVNBrushStrokeData, DVNBrushStrokePainter,
    LTParameterizedObjectType, LTTexture;

/// Protocol to be implemented by delegates of \c DVNBrushStrokePainter objects.
@protocol DVNBrushStrokePainterDelegate <NSObject>

/// Returns the data required for painting a brush stroke. The texture mapping provides the
/// textures required by the used brush model. More precisely, the keys of the returned texture
/// mapping correspond to the \c imageURLPropertyKeys of the \c brushModel of the returned
/// \c DVNBrushRenderModel.
///
/// @important This method is called at every beginning of a process sequence of the corresponding
/// \c DVNBrushStrokePainter.
///
/// @note The returned textures are not manipulated by the \c DVNBrushStrokePainter retrieving the
/// data.
- (std::pair<DVNBrushRenderModel *, NSDictionary<NSString *, LTTexture *> *>)brushStrokeData;

/// Returns the texture onto which a brush stroke is to be painted. Returns \c nil if the relevant
/// render target is already bound.
- (nullable LTTexture *)brushStrokeCanvas;

@optional

/// Returns the spline type to be used for painting the brush stroke determined by
/// \c brushRenderModel.
///
/// @note If not implemented, the corresponding \c DVNBrushStrokePainter uses
/// \c LTParameterizedObjectTypeBSpline as spline type.
- (LTParameterizedObjectType *)brushSplineType;

/// Called just before the given \c painter will start painting a brush stroke.
- (void)renderingOfPainterWillStart:(DVNBrushStrokePainter *)painter;

/// Called just after the given \c painter has continued painting a brush stroke, updating the given
/// \c quads of its canvas.
- (void)renderingOfPainter:(DVNBrushStrokePainter *)painter
        continuedWithQuads:(const std::vector<lt::Quad> &)quads;

/// Called just after the given \c painter has finished painting the given \c brushStroke.
- (void)renderingOfPainter:(DVNBrushStrokePainter *)painter
      endedWithBrushStroke:(DVNBrushStrokeSpecification *)brushStroke;

@end

/// Object representing a "painter" of "brush strokes", i.e. an entity which draws with a "brush"
/// along a spline onto a "canvas", yielding a visual brush stroke. The brush is described by a
/// \c DVNBrushModel, the spline consists of a sequence of \c LTSplineControlPoint objects, a
/// so-called spline control point sequence, and the canvas is either an \c LTTexture or a render
/// target assumed to be bound during the rendering. For every process sequence, as defined by the
/// \c DVNSplineRendering protocol, a different brush and canvas can be used.
///
/// In a more technical phrasing, objects of this class construct a continuous parameterized object
/// from an iteratively given sequence of control points and consecutively render geometry created
/// according to the spline and a \c DVNBrushRenderModel. The rendering is performed onto a render
/// target retrieved at every beginning and continuation of a process sequence. If no render target
/// is provided, the render target is assumed to be bound during processing the process sequence.
///
/// Objects of this class maintain a weakly held \c id<DVNBrushStrokePainterDelegate> object that is
/// used to retrieve all the data required for painting the next brush stroke and informed about
/// performed brush stroke and canvas clearing events.
///
/// @important The \c id<DVNBrushStrokePainterDelegate> object used by instances of this class must
/// not be deallocated before the last spline control point sequence provided to instances of this
/// class has begun.
@interface DVNBrushStrokePainter : NSObject <DVNSplineRendering>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c delegate which is held weakly. The \c delegate is provided upon
/// initialization in order to avoid the possibility of partial updates to a delegate which could
/// arise if it was possible to replace the delegate in the middle of a process sequence.
- (instancetype)initWithDelegate:(id<DVNBrushStrokePainterDelegate>)delegate
    NS_DESIGNATED_INITIALIZER;

/// Paints the brush strokes represented by the given \c brushStrokeData onto the given \c canvas.
/// The effect of this method is identical to creating a \c DVNBrushStrokePainter and processing
/// control point sequences with given \c brushStrokeData.
+ (void)paintBrushStrokesAccordingToData:(NSArray<DVNBrushStrokeData *> *)brushStrokeData
                              ontoCanvas:(LTTexture *)canvas;

/// Indication whether this instance is currently processing a content touch event sequence. Is set
/// to \c YES at the beginning of a sequence and set to \c NO at the end of the sequence.
/// KVO-compliant.
@property (readonly, nonatomic) BOOL currentlyProcessingContentTouchEventSequence;

/// Delegate informed about brush stroke rendering and canvas clearing events.
@property (weak, readonly, nonatomic) id<DVNBrushStrokePainterDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
