// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawer.h"

#import "LTFbo.h"
#import "LTRotatedRect.h"
#import "LTShapeDrawerEllipticShape.h"
#import "LTShapeDrawerPathShape.h"
#import "LTShapeDrawerTriangularMeshShape.h"

@interface LTShapeDrawer ()

@property (strong, nonatomic) LTShapeDrawerParams *drawingParameters;

/// Queue of shapes drawn by this drawer.
@property (strong, nonatomic) NSMutableArray *shapes;

@end

@implementation LTShapeDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    [self setup];
  }
  return self;
}

- (void)setup {
  self.opacity = self.defaultOpacity;
  self.drawingParameters = [[LTShapeDrawerParams alloc] init];
  self.shapes = [NSMutableArray array];
}

#pragma mark -
#pragma mark Draw
#pragma mark -

- (void)drawInFramebuffer:(LTFbo *)fbo {
  [fbo bindAndDraw:^{
    [self drawInBoundFramebufferWithSize:fbo.size];
  }];
}

- (void)drawInBoundFramebufferWithSize:(CGSize)size {
  for (id<LTDrawableShape> shape in self.shapes) {
    shape.opacity = self.opacity;
    [shape drawInBoundFramebufferWithSize:size];
  }
}

- (void)drawInScreenFramebufferWithSize:(CGSize)size {
  for (id<LTDrawableShape> shape in self.shapes) {
    shape.opacity = self.opacity;
    [shape drawInScreenFramebufferWithSize:size];
  }
}

- (void)removeAllShapes {
  [self.shapes removeAllObjects];
}

#pragma mark -
#pragma mark Path
#pragma mark -

- (id)addPathWithTranslation:(CGPoint)translation rotation:(CGFloat)rotation {
  LTShapeDrawerPathShape *shape =
      [[LTShapeDrawerPathShape alloc] initWithParams:self.drawingParameters];
  shape.translation = translation;
  shape.rotationAngle = rotation;
  [self.shapes addObject:shape];
  return shape;
}

- (void)moveToPoint:(CGPoint)point {
  LTShapeDrawerPathShape *path = [self lastShapeOfClass:[LTShapeDrawerPathShape class]];
  LTAssert(path, @"moveToPoint can be applied on an existing path.");
  [path moveToPoint:point];
}

- (void)addLineToPoint:(CGPoint)point {
  LTShapeDrawerPathShape *path = [self lastShapeOfClass:[LTShapeDrawerPathShape class]];
  LTAssert(path, @"addLineToPoint can be applied on an existing path.");
  [path addLineToPoint:point];
}

#pragma mark -
#pragma mark TriangularMesh
#pragma mark -

- (id)addTriangularMeshWithTranslation:(CGPoint)translation rotation:(CGFloat)rotation {
  LTShapeDrawerTriangularMeshShape *shape =
      [[LTShapeDrawerTriangularMeshShape alloc] initWithParams:self.drawingParameters];
  shape.translation = translation;
  shape.rotationAngle = rotation;
  [self.shapes addObject:shape];
  return shape;
}

- (void)fillTriangle:(CGTriangle)triangle withShadowOnEdges:(CGTriangleEdgeMask)edgeMask {
  LTShapeDrawerTriangularMeshShape *mesh =
      [self lastShapeOfClass:[LTShapeDrawerTriangularMeshShape class]];
  LTAssert(mesh, @"fillTriangle can be applied on an existing triangular mesh.");
  [mesh fillTriangle:triangle withShadowOnEdges:edgeMask];
}

#pragma mark -
#pragma mark Ellipses
#pragma mark -

- (id)addCircleWithCenter:(CGPoint)center radius:(CGFloat)radius {
  LTParameterAssert(radius >= 0);
  LTRotatedRect *rect =
      [LTRotatedRect rectWithCenter:center size:CGSizeMakeUniform(radius * 2) angle:0];
  return [self addEllipseInRotatedRect:rect];
}

- (id)addEllipseInRotatedRect:(LTRotatedRect *)rotatedRect {
  LTShapeDrawerEllipticShape *shape =
      [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rotatedRect filled:NO
                                                       params:self.drawingParameters];
  [self.shapes addObject:shape];
  return shape;
}

- (id)fillCircleWithCenter:(CGPoint)center radius:(CGFloat)radius {
  LTParameterAssert(radius >= 0);
  LTRotatedRect *rect =
      [LTRotatedRect rectWithCenter:center size:CGSizeMakeUniform(radius * 2) angle:0];
  return [self fillEllipseInRotatedRect:rect];
}

- (id)fillEllipseInRotatedRect:(LTRotatedRect *)rotatedRect {
  LTShapeDrawerEllipticShape *shape =
      [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rotatedRect filled:YES
                                                       params:self.drawingParameters];
  [self.shapes addObject:shape];
  return shape;
}

#pragma mark -
#pragma mark Shapes Queue
#pragma mark -

- (void)addShape:(id)shape {
  LTParameterAssert([shape conformsToProtocol:@protocol(LTDrawableShape)]);
  [self.shapes addObject:shape];
}

- (void)removeShape:(id)shape {
  [self.shapes removeObject:shape];
}

- (void)updateShape:(id)shape setTranslation:(CGPoint)translation {
  if (![self.shapes containsObject:shape]) {
    return;
  }
  
  LTParameterAssert([[shape class] conformsToProtocol:@protocol(LTDrawableShape)]);
  [(id<LTDrawableShape>)shape setTranslation:translation];
}

- (void)updateShape:(id)shape setRotation:(CGFloat)angle {
  if (![self.shapes containsObject:shape]) {
    return;
  }
  
  LTParameterAssert([[shape class] conformsToProtocol:@protocol(LTDrawableShape)]);
  [(id<LTDrawableShape>)shape setRotationAngle:angle];
}

/// Returns the last shape of the given class that exists in the shape queue, or nil if there is no
/// such shape.
- (id)lastShapeOfClass:(Class)aClass {
  for (NSInteger i = self.shapes.count - 1; i >= 0; --i) {
    if ([self.shapes[i] isKindOfClass:aClass]) {
      return self.shapes[i];
    }
  }
  return nil;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTBoundedPrimitivePropertyImplement(CGFloat, opacity, Opacity, 0, 1, 1);

@end
