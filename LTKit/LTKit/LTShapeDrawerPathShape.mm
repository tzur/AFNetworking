// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerPathShape.h"

#import "LTArrayBuffer.h"
#import "LTCGExtensions.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTShapeDrawerShapeVsh.h"
#import "LTShaderStorage+LTShapeDrawerPathShapeFsh.h"
#import "LTShapeDrawerParams.h"
#import "LTVertexArray.h"

@interface LTShapeDrawerPathShape ()

/// The starting point of the current subpath.
@property (nonatomic) CGPoint startingPoint;

/// The current point of the current subpath.
@property (nonatomic) CGPoint currentPoint;

@end

@implementation LTShapeDrawerPathShape

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTShapeDrawerShapeVsh source]
                                  fragmentSource:[LTShapeDrawerPathShapeFsh source]];
}

#pragma mark -
#pragma mark Vertices
#pragma mark -

- (void)moveToPoint:(CGPoint)point {
  self.startingPoint = point;
  self.currentPoint = point;
}

- (void)addLineToPoint:(CGPoint)point {
  LTShapeDrawerSegment segment = [self verticesForLineFrom:GLKVector2FromCGPoint(self.currentPoint)
                                                        to:GLKVector2FromCGPoint(point)];
  LTAddSegment(segment, &self.strokeVertices, &self.shadowVertices);
  self.currentPoint = point;
}

- (void)closePath {
  [self addLineToPoint:self.startingPoint];
}

- (LTShapeDrawerSegment)verticesForLineFrom:(GLKVector2)source to:(GLKVector2)target {
  CGFloat shadowWidth = self.params.shadowWidth;
  CGFloat lineRadius = self.params.lineRadius;
  GLKVector2 direction = GLKVector2Normalize(target - source);
  GLKVector2 normal = GLKVector2NormalTo(direction);
  CGFloat lineLength = GLKVector2Length(target - source);
  GLKVector4 offset = GLKVector4Make(1.0 + shadowWidth, 1.0 + shadowWidth + lineRadius,
                                     1.0 + shadowWidth, 1.0 + shadowWidth + lineRadius);
  
  LTShapeDrawerSegment segment;
  for (NSUInteger i = 0; i < 4; ++i) {
    segment.v[i].lineBounds =
        GLKVector4Make(0.5 * lineLength, lineRadius, 0.5 * lineLength, lineRadius);
    segment.v[i].shadowBounds = segment.v[i].lineBounds +
        GLKVector4Make(shadowWidth, shadowWidth, shadowWidth, shadowWidth);
    segment.v[i].color = self.params.strokeColor;
    segment.v[i].shadowColor = self.params.shadowColor;
  }
  
  source = source - direction * offset.x;
  target = target + direction * offset.z;
  
  segment.src0.position = source - normal * offset.y;
  segment.src1.position = source + normal * offset.w;
  segment.dst0.position = target - normal * offset.y;
  segment.dst1.position = target + normal * offset.w;
  
  segment.src0.offset = GLKVector2Make(-0.5 * lineLength - offset.x, -offset.y);
  segment.src1.offset = GLKVector2Make(-0.5 * lineLength - offset.x, offset.w);
  segment.dst0.offset = GLKVector2Make(0.5 * lineLength + offset.z, -offset.y);
  segment.dst1.offset = GLKVector2Make(0.5 * lineLength + offset.z, offset.w);
  
  return segment;
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawInBoundFramebufferWithSize:(CGSize)size {
  [self setProjectionForFramebufferWithSize:size];
  [self drawWithClockwiseFrontFacingPolygons:NO];
}

- (void)drawInScreenFramebufferWithSize:(CGSize)size {
  [self setProjectionForScreenFramebufferWithSize:size];
  [self drawWithClockwiseFrontFacingPolygons:YES];
}

- (void)drawWithClockwiseFrontFacingPolygons:(BOOL)cwffPolygons {
  [self updateBuffer];
  [self setUniforms];
  LTGLContext *context = [LTGLContext currentContext];
  [context executeAndPreserveState:^{
    context.clockwiseFrontFacingPolygons = cwffPolygons;
    [self.context drawWithMode:LTDrawingContextDrawModeTriangles];
  }];
}

- (void)setUniforms {
  GLKMatrix4 modelview =
      GLKMatrix4Rotate(GLKMatrix4MakeTranslation(self.translation.x, self.translation.y, 0),
                       self.rotationAngle, 0, 0, 1);
  
  self.program[[LTShapeDrawerShapeVsh modelview]] = $(modelview);
  self.program[[LTShapeDrawerPathShapeFsh opacity]] = @(self.opacity);
}

- (void)setProjectionForFramebufferWithSize:(CGSize)size {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, 0, size.height, -1, 1);
  self.program[[LTShapeDrawerShapeVsh projection]] = $(projection);
}

- (void)setProjectionForScreenFramebufferWithSize:(CGSize)size {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, size.height, 0, -1, 1);
  self.program[[LTShapeDrawerShapeVsh projection]] = $(projection);
}

@end
