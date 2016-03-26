// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTSolidRectsDrawer.h"

#import "LTFbo.h"
#import "LTMultiRectDrawer.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTSolidRectsDrawerFsh.h"
#import "LTShaderStorage+LTSolidRectsDrawerVsh.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTSolidRectsDrawer ()

/// Auxiliary multi rects drawer. The drawer makes a solid color texture to be drawn on an input
/// image texture only in rects specified. This practically leads to a solid color drawing effect.
/// The cause for the aliased drawing is that the \c LTMultiRectDrawer sends to the vertex shader
/// the vertices of the rectangles that need to be drawn. Then, the rasterizer passes to the
/// fragment shader only pixels that lies completely inside those rectangles.
@property (readonly, nonatomic) LTMultiRectDrawer *rectDrawer;

@end

@implementation LTSolidRectsDrawer

- (instancetype)initWithFillColor:(LTVector4)fillColor {
  LTParameterAssert(!fillColor.isNull());
  if (self = [super init]) {
    _rectDrawer = [[LTMultiRectDrawer alloc] initWithProgram:[self createDrawingProgram]
                                               sourceTexture:[self dummyTexture]];
    self.rectDrawer[[LTSolidRectsDrawerFsh color]] = $(fillColor);
  }
  return self;
}


- (LTTexture *)dummyTexture {
  return [LTTexture textureWithImage:cv::Mat4b(1, 1)];
}

- (LTProgram *)createDrawingProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTSolidRectsDrawerVsh source]
                                  fragmentSource:[LTSolidRectsDrawerFsh source]];
}

- (void)drawRotatedRects:(NSArray<LTRotatedRect *> *)rects inFramebuffer:(LTFbo *)fbo {
  NSMutableArray<LTRotatedRect *> *pixelRects = [self pixelRectsCollectionOfSize:rects.count];

  [self.rectDrawer drawRotatedRects:rects inFramebuffer:fbo fromRotatedRects:pixelRects];
}

- (NSMutableArray<LTRotatedRect *> *)pixelRectsCollectionOfSize:(NSUInteger)size {
  NSMutableArray<LTRotatedRect *> *pixelRects = [NSMutableArray array];

  CGRect pixelRect = CGRectFromSize(CGSizeMakeUniform(1));
  for (NSUInteger i = 0; i < size; ++i) {
    [pixelRects addObject:[LTRotatedRect rect:pixelRect]];
  }

  return pixelRects;
}

@end

NS_ASSUME_NONNULL_END
