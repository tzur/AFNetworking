// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPropertyMacros.h"

#import "LTCGExtensions.h"
#import "LTShapeDrawerParams.h"

@class LTFbo, LTRotatedRect;

/// Class for efficiently drawing simple vector graphics used for overlays. This tries to give a
/// similar interface to the Core Graphics drawing (CGContextDoSomething functions) with the
/// necessary optimization of trying to reduce the amount of buffers copied between the cpu and gpu.
/// This is done by providing an interface to update the translation / rotation of existing shapes,
/// based on the assumption that in many scenarios the same shapes are drawn in every frame, when
/// only their position / rotation is updated.
///
/// To add support for additional shapes, simply add a class implementing the \c LTDrawableShape
/// protocol. Then add a helper method to create it in this class, creating the instance and adding
/// it to the shapes queue.
@interface LTShapeDrawer : NSObject

/// Removes all shapes from the shape queue.
- (void)removeAllShapes;

/// Removes the given shape from the shape queue. Nothing will happen in case the given shape is not
/// a valid shape or does not exist in the shape queue.
- (void)removeShape:(id)shape;

/// Adds the given shape to the shape queue. This must be a shape returned by one of the drawer's
/// shape generating methods, and it is not affected by the current \c drawingParameters.
- (void)addShape:(id)shape;

/// Adds a path shape with the given translation and rotation.
///
/// @return shape object that can be used for adding/removing/updating the shape.
/// @note Following calls to \c moveToPoint or \c addLineToPoint will affect this path shape object.
- (id)addPathWithTranslation:(CGPoint)translation rotation:(CGFloat)rotation;

/// Begins a new subpath at the specified point.
///
/// @note This subpath will be added to the last added path shape object, and will raise an
/// exception if there's no such object in the shape queue.
- (void)moveToPoint:(CGPoint)point;

/// Appends a straight line segment from the current point to the given point.
///
/// @note This segment will be added to the last added path shape object, and will raise an
/// exception if there's no such object in the shape queue.
- (void)addLineToPoint:(CGPoint)point;

/// Adds a triangular mesh shape (for drawing filled shapes consisting of triangles) with the given
/// translation and rotation.
///
/// @return shape object that can be used for adding/removing/updating the shape.
/// @note Following calls to \c fillTriangle:withShadowOnEdges: will affect this mesh object.
- (id)addTriangularMeshWithTranslation:(CGPoint)translation rotation:(CGFloat)rotation;

/// Fills the given triangle with shadows according to the given edge mask.
///
/// @note This triangle will be added to the last added triangular mesh shape object, and will raise
/// an exception if there's no such object in the shape queue.
- (void)fillTriangle:(CGTriangle)triangle withShadowOnEdges:(CGTriangleEdgeMask)edgeMask;

/// Adds an ellipse (outline) that fits inside the specified rotated rectangle.
///
/// @return shape object that can be used for adding/removing/updating the shape.
- (id)addEllipseInRotatedRect:(LTRotatedRect *)rotatedRect;

/// Paints the area of the ellipse that fits inside the provided rotated rectangle.
///
/// @return shape object that can be used for adding/removing/updating the shape.
- (id)fillEllipseInRotatedRect:(LTRotatedRect *)rotatedRect;

/// Adds a circle (outline) with the given center and radius.
///
/// @return shape object that can be used for adding/removing/updating the shape.
- (id)addCircleWithCenter:(CGPoint)center radius:(CGFloat)radius;

/// Paints the area of the circle with the given center and radius.
///
/// @return shape object that can be used for adding/removing/updating the shape.
- (id)fillCircleWithCenter:(CGPoint)center radius:(CGFloat)radius;

/// Updates the translation of the given shape, if it exists in the shapes queue.
///
/// @note This is done without regenerating or updating the vertices buffer of the shape.
- (void)updateShape:(id)shape setTranslation:(CGPoint)translation;

/// Updates the rotation angle of the given shape, if exists in the shapes queue.
///
/// @note This is done without regenerating or updating the vertices buffer of the shape.
- (void)updateShape:(id)shape setRotation:(CGFloat)angle;

/// Draws all shapes in this drawer's queue on the given framebuffer.
- (void)drawInFramebuffer:(LTFbo *)fbo;

/// Draws all shapes in this drawer's queue on the currently bound framebuffer.
- (void)drawInFramebufferWithSize:(CGSize)size;

/// Opacity to use when drawing the shapes in the shape queue. Must be in range [0,1].
///
/// @note Updating this property affects the opacity of all shapes in the queue, as this is done
/// without updating the vertices buffer or each shape, and allows animating the opacity with ease.
@property (nonatomic) CGFloat opacity;
LTPropertyDeclare(CGFloat, opacity, Opacity);

/// Drawing parameters applied to newly added shapes.
///
/// @note Although this property is read-only, its own properties are read/write.
/// Use these properties primarily to configure the parameters applied to generated shapes.
/// @note Updating any of the drawing parameters will not affect shapes that were already added to
/// the shape queue. Newly added shapes will be added with the parameters at time of addition.
@property (readonly, nonatomic) LTShapeDrawerParams *drawingParameters;

/// Array of shapes that the shape drawer holds.
@property (readonly, nonatomic) NSArray *shapes;

@end
