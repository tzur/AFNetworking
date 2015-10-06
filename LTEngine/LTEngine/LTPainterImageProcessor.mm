// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterImageProcessor.h"

#import "LTLinearInterpolationRoutine.h"
#import "LTPaintingStrategy.h"
#import "LTPainter+LTView.h"
#import "LTProgressiveImageProcessor+Protected.h"
#import "LTTexture.h"

@interface LTPainterImageProcessor ()

/// Painter used by the processor to paint on its canvas.
@property (strong, nonatomic) LTPainter *painter;

/// Painting strategy used by the processor to decide what and how to paint on its canvas.
@property (strong, nonatomic) id<LTPaintingStrategy> strategy;

@end

@implementation LTPainterImageProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCanvasTexture:(LTTexture *)canvasTexture
                     paintingStrategy:(id<LTPaintingStrategy>)strategy {
  LTParameterAssert(canvasTexture);
  LTParameterAssert(strategy);
  if (self = [super init]) {
    self.strategy = strategy;
    [self createPainterWithTexture:canvasTexture];
  }
  return self;
}

- (void)createPainterWithTexture:(LTTexture *)texture {
  self.painter =
      [[LTPainter alloc] initWithMode:LTPainterTargetModeDirectStroke canvasTexture:texture];
  self.painter.splineFactory = [[LTLinearInterpolationRoutineFactory alloc] init];
}

#pragma mark -
#pragma mark LTImageProcessor
#pragma mark -

- (void)process {
  if (!self.processedProgress) {
    [self.strategy paintingWillBeginWithPainter:self.painter];
  }
  
  if (self.processedProgress < self.targetProgress) {
    NSArray *directionsArray =
        [self.strategy paintingDirectionsForStartingProgress:self.processedProgress
                                              endingProgress:self.targetProgress];

    for (LTPaintingDirections *directions in directionsArray) {
      self.painter.brush = directions.brush;
      [self.painter paintStroke:directions.stroke];
    }
    self.processedProgress = self.targetProgress;
  }
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGSize)canvasSize {
  return self.painter.canvasTexture.size;
}

@end
