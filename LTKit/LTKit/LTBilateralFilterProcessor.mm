// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBilateralFilterProcessor.h"

#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTBilateralFilterFsh.h"
#import "LTShaderStorage+LTBilateralFilterVsh.h"
#import "LTTexture.h"

@interface LTBilateralFilterProcessor ()
@property (nonatomic) CGSize inputSize;
@property (nonatomic) CGSize outputSize;
@end

@implementation LTBilateralFilterProcessor

- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs {
  LTProgram *program = [self createProgram];
  if (self = [super initWithProgram:program sourceTexture:input
                  auxiliaryTextures:@{@"originalTexture": input} outputs:outputs]) {
    self.inputSize = input.size;
    self.outputSize = [[outputs firstObject] size];
  }
  return self;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTShaderStorage LTBilateralFilterVsh]
                                  fragmentSource:[LTShaderStorage LTBilateralFilterFsh]];
}

- (void)iterationStarted:(NSUInteger)iteration {
  if (!iteration) {
    // Horizontal with source width.
    CGFloat width = self.inputSize.width;
    self[@"texelOffset"] = [NSValue valueWithGLKVector2:GLKVector2Make(1.0 / width, 0)];
  } else if (iteration % 2) {
    // Vertical.
    CGFloat height = self.outputSize.height;
    self[@"texelOffset"] = [NSValue valueWithGLKVector2:GLKVector2Make(0, 1.0 / height)];
  } else {
    // Horizontal.
    CGFloat width = self.outputSize.width;
    self[@"texelOffset"] = [NSValue valueWithGLKVector2:GLKVector2Make(1.0 / width, 0)];
  }
}

- (NSArray *)iterationsPerOutput {
  NSArray *iterationsPerOutput = super.iterationsPerOutput;
  return [self multiplyArray:iterationsPerOutput withValue:0.5];
}

- (void)setIterationsPerOutput:(NSArray *)iterationsPerOutput {
  NSArray *iterations = [self multiplyArray:iterationsPerOutput withValue:2];
  [super setIterationsPerOutput:iterations];
}

- (NSArray *)multiplyArray:(NSArray *)originalIterations withValue:(double)value {
  NSMutableArray *iterations = [NSMutableArray array];
  for (NSNumber *number in originalIterations) {
    [iterations addObject:@([number unsignedIntegerValue] * value)];
  }
  return [iterations copy];
}

- (void)setRangeSigma:(float)rangeSigma {
  self[@"rangeSigma"] = @(rangeSigma);
}

- (float)rangeSigma {
  return [self[@"rangeSigma"] floatValue];
}

@end
