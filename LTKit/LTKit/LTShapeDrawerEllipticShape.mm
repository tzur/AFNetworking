// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerEllipticShape.h"

#import "LTArrayBuffer.h"
#import "LTCGExtensions.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTShapeDrawerShapeVsh.h"
#import "LTShaderStorage+LTShapeDrawerEllipticShapeFsh.h"
#import "LTShapeDrawerParams.h"
#import "LTRotatedRect.h"

@interface LTShapeDrawerEllipticShape ()

/// Holds the drawing parameters that were used to generate the existing vertices.
@property (strong, nonatomic) LTShapeDrawerParams *paramsForExistingVertices;

/// \c YES iff the generated shape is a filled ellipse.
@property (nonatomic) BOOL filled;

/// The size of the axis-aligned ellipse.
@property (nonatomic) CGSize rectSize;

@end

@implementation LTShapeDrawerEllipticShape

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithRotatedRect:(LTRotatedRect *)rotatedRect filled:(BOOL)filled
                             params:(LTShapeDrawerParams *)params {
  LTParameterAssert(rotatedRect);
  if (self = [super initWithParams:params]) {
    self.filled = filled;
    self.rectSize = rotatedRect.rect.size;
    self.translation = rotatedRect.center;
    self.rotationAngle = rotatedRect.angle;
  }
  return self;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTShapeDrawerShapeVsh source]
                                  fragmentSource:[LTShapeDrawerEllipticShapeFsh source]];
}

#pragma mark -
#pragma mark Vertices
#pragma mark -

- (void)updateVertices {
  if (self.filled) {
    [self updateVerticesForFilledEllipse];
  } else {
    [self updateVerticesForNonFilledEllipse];
  }
}

- (void)updateVerticesForFilledEllipse {
  LTShapeDrawerSegment segment;
  CGSize halfSize = self.rectSize / 2;
  for (NSUInteger i = 0; i < 4; ++i) {
    segment.v[i].lineBounds = GLKVector4Make(halfSize.width, halfSize.height, 0, 0);
    segment.v[i].shadowBounds = GLKVector4Make(self.params.shadowWidth + 1.0, 0, 0, 0);
    segment.v[i].color = self.params.fillColor;
    segment.v[i].shadowColor = self.params.shadowColor;
  }

  CGSize size = self.rectSize + CGSizeMakeUniform(1.0 + 2.0 * self.params.shadowWidth);
  LTRotatedRect *rect = [LTRotatedRect rectWithCenter:CGPointZero size:size angle:0];
  segment.src0.position = GLKVector2FromCGPoint(rect.v0);
  segment.src1.position = GLKVector2FromCGPoint(rect.v1);
  segment.dst0.position = GLKVector2FromCGPoint(rect.v3);
  segment.dst1.position = GLKVector2FromCGPoint(rect.v2);
  
  segment.src0.offset = segment.src0.position;
  segment.src1.offset = segment.src1.position;
  segment.dst0.offset = segment.dst0.position;
  segment.dst1.offset = segment.dst1.position;
  
  LTAddSegment(segment, &self.strokeVertices, &self.shadowVertices);
}

- (void)updateVerticesForNonFilledEllipse {
  static const CGFloat kMinSegments = 1;
  static const CGFloat kMaxSegments = 1000;
  CGFloat segments = MIN(kMaxSegments, MAX(kMinSegments, 2 * M_PI * std::max(self.rectSize)));
  float step = 2.0 * M_PI / segments;
  
  CGFloat offset = 1.0 + self.params.lineRadius + self.params.shadowWidth;
  CGSize radius = self.rectSize / 2;
  for (NSUInteger i = 0; i < segments - 1; ++i) {
    LTShapeDrawerSegment segment;
    for (NSUInteger i = 0; i < 4; ++i) {
      segment.v[i].lineBounds = GLKVector4Make(1, self.params.lineRadius,
                                               1, self.params.lineRadius);
      segment.v[i].shadowBounds = GLKVector4Make(offset, offset, offset, offset);
      segment.v[i].color = self.params.strokeColor;
      segment.v[i].shadowColor = self.params.shadowColor;
    }
    
    segment.src0.position = GLKVector2Make(cos(i * step) * (radius.width - offset),
                                           sin(i * step) * (radius.height - offset));
    segment.src1.position = GLKVector2Make(cos(i * step) * (radius.width + offset),
                                           sin(i * step) * (radius.height + offset));
    segment.dst0.position = GLKVector2Make(cos((i + 1) * step) * (radius.width - offset),
                                           sin((i + 1) * step) * (radius.height - offset));
    segment.dst1.position = GLKVector2Make(cos((i + 1) * step) * (radius.width + offset),
                                           sin((i + 1) * step) * (radius.height + offset));
    
    segment.src0.offset = GLKVector2Make(0, -offset);
    segment.src1.offset = GLKVector2Make(0, offset);
    segment.dst0.offset = GLKVector2Make(0, -offset);
    segment.dst1.offset = GLKVector2Make(0, offset);
    
    LTAddSegment(segment, &self.strokeVertices, &self.shadowVertices);
  }
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
  if (![self.params isEqual:self.paramsForExistingVertices]) {
    [self updateVertices];
    [self updateBuffer];
    self.paramsForExistingVertices = [self.params copy];
  }
  
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
  self.program[[LTShapeDrawerEllipticShapeFsh opacity]] = @(self.opacity);
  self.program[[LTShapeDrawerEllipticShapeFsh filled]] = @(self.filled);
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
