// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPropertyMacros.h"
#import "LTShapeDrawerShapeCommon.h"

@class LTArrayBuffer, LTDrawingContext, LTProgram, LTShapeDrawerParams;

/// @protocol LTDrawableShape
///
/// By implementing this protocol, a class can be drawn by the \c LTShapeDrawer.
/// The protocol contains two parts: the draw methods are used by the \c LTShapeDrawer to perform
/// the actual drawing, depending on the target (texture or screen).
/// The opacity/translation/rotationAngle setters and getters allow it to update the shape without
/// updating its vertices (which can be expensive, in case of a shape with many vertices).
@protocol LTDrawableShape <NSObject>

/// Draws the shape on the currently bound framebuffer.
- (void)drawInBoundFramebufferWithSize:(CGSize)size;

/// Draws the shape on the currently bound screen framebuffer.
- (void)drawInScreenFramebufferWithSize:(CGSize)size;

/// Sets the opacity of the shape to draw.
- (void)setOpacity:(CGFloat)opacity;

/// The opacity of the shape to draw.
- (CGFloat)opacity;

/// Sets the translation of the shape (from the origin).
- (void)setTranslation:(CGPoint)translation;

/// The translation of the shape (from the origin).
- (CGPoint)translation;

/// Sets the rotation angle (clockwise, around the origin) of the shape.
- (void)setRotationAngle:(CGFloat)angle;

/// The rotation angle (clockwise, around the origin) of the shape.
- (CGFloat)rotationAngle;

@end

/// @class LTShapeDrawerShape
///
/// Abstract class sharing some common funcionality shared between the different shapes.
@interface LTShapeDrawerShape : NSObject

/// Initializes the shape drawer with the given drawer parameters.
- (instancetype)initWithParams:(LTShapeDrawerParams *)params;

/// Abstract method. The subclass should return shader program it uses for drawing the shape.
- (LTProgram *)createProgram;

/// Name of the \c GPUStruct used by the drawer's vertex array. Subclasses using a different vertex
/// shader should override this method and return the name of the \c GPUStruct used.
- (NSString *)vertexShaderStructName;

/// Attributes of the vertex shader used by the drawer. Subclasses using a different vertex shader
/// should override this method and return the list of attributes used.
- (NSArray *)vertexShaderAttributes;

/// Updates the array buffer with the current vertices. Subclasses using a different vertex shader
/// struct should override this method and update the buffer according to the vertices and struct
/// size.
- (void)updateBuffer;

/// Configurable drawer parameters.
@property (readonly, nonatomic) LTShapeDrawerParams *params;

/// Vertices used for drawing the shape / outline.
@property (readonly, nonatomic) LTShapeDrawerVertices &strokeVertices;

/// Vertices used for drawing the shadow around the shape / outline.
@property (readonly, nonatomic) LTShapeDrawerVertices &shadowVertices;

/// Program used for drawing the shape.
@property (readonly, nonatomic) LTProgram *program;

/// Context holding the geometry and program.
@property (readonly, nonatomic) LTDrawingContext *context;

/// Array buffer used for drawing the shape.
@property (readonly, nonatomic) LTArrayBuffer *arrayBuffer;

/// Opacity of the shape.
LTBoundedPrimitiveProperty(CGFloat, opacity, Opacity);

@end

@interface LTShapeDrawerShape (ForTesting)

/// Clears the cached shader programs.
+ (void)clearPrograms;

@end
