// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Drawing modes that specify what kind of primitive to render.
typedef NS_ENUM(NSUInteger, LTDrawingContextDrawMode) {
  LTDrawingContextDrawModeTriangleStrip = GL_TRIANGLE_STRIP,
  LTDrawingContextDrawModeTriangles = GL_TRIANGLES,
  LTDrawingContextDrawModeLines = GL_LINES
};

@class LTArrayBuffer, LTProgram, LTTexture, LTVertexArray;

/// @class LTDrawingContext
///
/// Context for drawing using the GPU. The context is responsible for binding a vertex array to a
/// program, and to manage resource binding before and after the drawing operation.
@interface LTDrawingContext : NSObject

/// Creates a new drawing context, and binds the vertex array's attributes to the given program's
/// attribute indices.
///
/// @param program program to execute in this context.
/// @param vertexArray vertex array to bind to the program. The given array must be \c complete.
/// @param uniformToTexture maps between uniform name (\c NSString) to its corresponding \c
/// LTTexture. The given uniforms must be a subset of the \c program uniforms set.
- (id)initWithProgram:(LTProgram *)program vertexArray:(LTVertexArray *)vertexArray
     uniformToTexture:(NSDictionary *)uniformToTexture;

/// Executes the \c program which uses the data in the \c vertexArray, together with the given
/// textures to draw to the bounded framebuffer.
- (void)drawWithMode:(LTDrawingContextDrawMode)mode;

/// Program to use in this execution context.
@property (readonly, nonatomic) LTProgram *program;

/// Vertex array which holds the vertex data.
@property (readonly, nonatomic) LTVertexArray *vertexArray;

/// Maps uniform name (\c NSString) to its associated texture (\c LTGLTexture).
@property (readonly, nonatomic) NSDictionary *uniformToTexture;

@end
