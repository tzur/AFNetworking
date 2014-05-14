// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

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

/// The translation of the shape (from the origin).
@property (nonatomic) CGPoint translation;

/// The rotation angle (clockwise, around the origin) of the shape.
@property (nonatomic) CGFloat rotationAngle;

/// The opacity of the shape to draw.
@property (nonatomic) CGFloat opacity;

@end

/// @class LTCommonDrawableShape
///
/// Abstract class sharing common funcionality shared between the different shapes.
///
/// @note While not mandatory, most of the \c LTDrawableShape implementations are likely to inherit
/// from this class, adding the missing functionality required by the \c LTDrawableShape protocol.
@interface LTCommonDrawableShape : NSObject

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

/// The translation of the shape (from the origin).
@property (nonatomic) CGPoint translation;

/// The rotation angle (clockwise, around the origin) of the shape.
@property (nonatomic) CGFloat rotationAngle;

/// The opacity of the shape to draw.
@property (nonatomic) CGFloat opacity;

@end

@interface LTCommonDrawableShape (ForTesting)

/// Clears the cached shader programs.
+ (void)clearPrograms;

@end
