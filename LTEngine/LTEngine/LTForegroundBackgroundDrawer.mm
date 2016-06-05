// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTForegroundBackgroundDrawer.h"

#import "LTFbo.h"
#import "LTRectDrawer.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTForegroundBackgroundDrawer ()

/// Rectangle that is used for determining where to use the \c foregroundDrawer and where to use the
/// \c backgroundDrawer while drawing.
@property (readonly, nonatomic) CGRect foregroundRect;

@end

@implementation LTForegroundBackgroundDrawer

- (instancetype)initWithForegroundDrawer:(id<LTTextureDrawer>)foregroundDrawer
                        backgroundDrawer:(id<LTTextureDrawer>)backgroundDrawer
                          foregroundRect:(CGRect)foregroundRect {
  LTParameterAssert(backgroundDrawer);
  LTParameterAssert(foregroundDrawer);

  if (self = [super init]) {
    _foregroundDrawer = foregroundDrawer;
    _backgroundDrawer = backgroundDrawer;
    _foregroundRect = foregroundRect;
  }

  return self;
}

#pragma mark -
#pragma mark Draw
#pragma mark -

- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect {
  [fbo bindAndDraw:^{
    [self drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
  }];
}

- (void)drawRect:(CGRect)targetRect inFramebufferWithSize:(CGSize)size fromRect:(CGRect)sourceRect {
  // If the source rect is completely contained in the foreground rect, only the foreground drawer
  // is needed.
  if (CGRectContainsRect(self.foregroundRect, sourceRect)) {
    [self.foregroundDrawer drawRect:targetRect inFramebufferWithSize:size fromRect:sourceRect];
    return;
  }

  [self.backgroundDrawer drawRect:targetRect inFramebufferWithSize:size fromRect:sourceRect];
  CGRect sourceForegroundRect = CGRectIntersection(self.foregroundRect, sourceRect);

  // If the source rect is completely contained in the background, there is no need to call the
  // foreground drawer after calling the background drawer.
  if (CGRectIsEmpty(sourceForegroundRect)) {
    return;
  }

  CGRect targetForegroundRect = [self mappedTargetRectFromTatgetRect:targetRect
                                                          sourceRect:sourceRect
                                                    mappedSourceRect:sourceForegroundRect];
  [self.foregroundDrawer drawRect:targetForegroundRect inFramebufferWithSize:size
                         fromRect:sourceForegroundRect];
}

- (CGRect)mappedTargetRectFromTatgetRect:(CGRect)targetRect sourceRect:(CGRect)sourceRect
                        mappedSourceRect:(CGRect)mappedSourceRect {
  CGSize sourceTargetSizeRatio = targetRect.size / sourceRect.size;

  CGPoint mappedOrigin = targetRect.origin + sourceTargetSizeRatio *
      (mappedSourceRect.origin - sourceRect.origin);
  CGSize mappedSize = mappedSourceRect.size * sourceTargetSizeRatio;

  return CGRectFromOriginAndSize(mappedOrigin, mappedSize);
}

@end

NS_ASSUME_NONNULL_END
