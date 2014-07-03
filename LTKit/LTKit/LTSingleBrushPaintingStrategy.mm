// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSingleBrushPaintingStrategy.h"

#import "LTBrush.h"

@interface LTSingleBrushPaintingStrategy ()
@property (strong ,nonatomic) LTBrush *brush;
@end

@implementation LTSingleBrushPaintingStrategy

- (instancetype)initWithBrush:(LTBrush *)brush {
  LTParameterAssert(brush);
  if (self = [super init]) {
    self.brush = brush;
  }
  return self;
}

- (void)paintingWillBeginWithPainter:(LTPainter __unused *)painter {
  LTMethodNotImplemented();
}

- (NSArray *)paintingDirectionsForStartingProgress:(__unused double)startingProgress
                                    endingProgress:(__unused double)endingProgress {
  LTMethodNotImplemented();
}

- (LTRandom *)random {
  return self.brush.random;
}

@end
