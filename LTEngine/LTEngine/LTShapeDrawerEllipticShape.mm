// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerEllipticShape.h"

#import "LTArrayBuffer.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTCommonDrawableShapeVsh.h"
#import "LTShaderStorage+LTShapeDrawerEllipticShapeFsh.h"
#import "LTShapeDrawerParams.h"
#import "LTRotatedRect.h"

@interface LTShapeDrawerEllipticShape ()

@property (nonatomic) BOOL filled;
@property (nonatomic) CGSize size;

/// Holds the drawing parameters that were used to generate the existing vertices.
@property (strong, nonatomic) LTShapeDrawerParams *paramsForExistingVertices;

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
    self.size = rotatedRect.rect.size;
    self.translation = rotatedRect.center;
    self.rotationAngle = rotatedRect.angle;
  }
  return self;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTCommonDrawableShapeVsh source]
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
  LTCommonDrawableShapeSegment segment;
  CGSize halfSize = self.size / 2;
  for (NSUInteger i = 0; i < 4; ++i) {
    segment.v[i].lineBounds = LTVector4(halfSize.width, halfSize.height, 0, 0);
    segment.v[i].shadowBounds = LTVector4(self.params.shadowWidth + 1.0, 0, 0, 0);
    segment.v[i].color = self.params.fillColor;
    segment.v[i].shadowColor = self.params.shadowColor;
  }

  CGSize size = self.size + CGSizeMakeUniform(1.0 + 2.0 * self.params.shadowWidth);
  LTRotatedRect *rect = [LTRotatedRect rectWithCenter:CGPointZero size:size angle:0];
  segment.src0.position = LTVector2(rect.v0);
  segment.src1.position = LTVector2(rect.v1);
  segment.dst0.position = LTVector2(rect.v3);
  segment.dst1.position = LTVector2(rect.v2);
  
  segment.src0.offset = segment.src0.position;
  segment.src1.offset = segment.src1.position;
  segment.dst0.offset = segment.dst0.position;
  segment.dst1.offset = segment.dst1.position;
  
  LTAddSegment(segment, &self.strokeVertices, &self.shadowVertices);
}

- (void)updateVerticesForNonFilledEllipse {
  static const CGFloat kMinSegments = 1;
  static const CGFloat kMaxSegments = 1000;
  CGFloat segments = MIN(kMaxSegments, MAX(kMinSegments, 2 * M_PI * std::max(self.size)));
  float step = 2.0 * M_PI / segments;
  
  CGFloat offset = 1.0 + self.params.lineRadius + self.params.shadowWidth;
  CGSize radius = self.size / 2;
  for (NSUInteger i = 0; i < segments - 1; ++i) {
    LTCommonDrawableShapeSegment segment;
    for (NSUInteger i = 0; i < 4; ++i) {
      segment.v[i].lineBounds = LTVector4(1, self.params.lineRadius,
                                               1, self.params.lineRadius);
      segment.v[i].shadowBounds = LTVector4(offset, offset, offset, offset);
      segment.v[i].color = self.params.strokeColor;
      segment.v[i].shadowColor = self.params.shadowColor;
    }
    
    segment.src0.position = LTVector2(cos(i * step) * (radius.width - offset),
                                           sin(i * step) * (radius.height - offset));
    segment.src1.position = LTVector2(cos(i * step) * (radius.width + offset),
                                           sin(i * step) * (radius.height + offset));
    segment.dst0.position = LTVector2(cos((i + 1) * step) * (radius.width - offset),
                                           sin((i + 1) * step) * (radius.height - offset));
    segment.dst1.position = LTVector2(cos((i + 1) * step) * (radius.width + offset),
                                           sin((i + 1) * step) * (radius.height + offset));
    
    segment.src0.offset = LTVector2(0, -offset);
    segment.src1.offset = LTVector2(0, offset);
    segment.dst0.offset = LTVector2(0, -offset);
    segment.dst1.offset = LTVector2(0, offset);
    
    LTAddSegment(segment, &self.strokeVertices, &self.shadowVertices);
  }
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawInFramebufferWithSize:(CGSize)size {
  if ([LTGLContext currentContext].renderingToScreen) {
    [self setProjectionForScreenFramebufferWithSize:size];
    [self drawWithClockwiseFrontFacingPolygons:YES];
  } else {
    [self setProjectionForFramebufferWithSize:size];
    [self drawWithClockwiseFrontFacingPolygons:NO];
  }
}

- (void)drawWithClockwiseFrontFacingPolygons:(BOOL)cwffPolygons {
  if (![self.params isEqual:self.paramsForExistingVertices]) {
    [self updateVertices];
    [self updateBuffer];
    self.paramsForExistingVertices = [self.params copy];
  }
  
  [self setUniforms];
  [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
    context.clockwiseFrontFacingPolygons = cwffPolygons;
    [self.context drawWithMode:LTDrawingContextDrawModeTriangles];
  }];
}

- (void)setUniforms {
  GLKMatrix4 modelview =
      GLKMatrix4Rotate(GLKMatrix4MakeTranslation(self.translation.x, self.translation.y, 0),
                       self.rotationAngle, 0, 0, 1);
  
  self.program[[LTCommonDrawableShapeVsh modelview]] = $(modelview);
  self.program[[LTShapeDrawerEllipticShapeFsh opacity]] = @(self.opacity);
  self.program[[LTShapeDrawerEllipticShapeFsh filled]] = @(self.filled);
}

- (void)setProjectionForFramebufferWithSize:(CGSize)size {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, 0, size.height, -1, 1);
  self.program[[LTCommonDrawableShapeVsh projection]] = $(projection);
}

- (void)setProjectionForScreenFramebufferWithSize:(CGSize)size {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, size.height, 0, -1, 1);
  self.program[[LTCommonDrawableShapeVsh projection]] = $(projection);
}

@end
