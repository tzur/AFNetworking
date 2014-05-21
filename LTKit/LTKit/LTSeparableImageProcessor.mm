// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSeparableImageProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTTexture.h"

@interface LTSeparableImageProcessor ()
@property (nonatomic) CGSize inputSize;
@property (nonatomic) CGSize outputSize;
@end

@implementation LTSeparableImageProcessor

- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)sourceTexture
                        outputs:(NSArray *)outputs {
  return [self initWithProgram:program sourceTexture:sourceTexture
             auxiliaryTextures:nil outputs:outputs];
}

- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)sourceTexture
              auxiliaryTextures:(NSDictionary *)auxiliaryTextures outputs:(NSArray *)outputs {
  LTParameterAssert([program containsUniform:@"texelOffset"]);
  if (self = [super initWithProgram:program sourceTexture:sourceTexture
                  auxiliaryTextures:auxiliaryTextures outputs:outputs]) {
    self.inputSize = sourceTexture.size;
    self.outputSize = [[outputs firstObject] size];
  }
  return self;
}

- (void)iterationStarted:(NSUInteger)iteration {
  if (!iteration) {
    // Horizontal with source width.
    CGFloat width = self.inputSize.width;
    self[@"texelOffset"] = $(GLKVector2Make(1.0 / width, 0));
  } else if (iteration % 2) {
    // Vertical.
    CGFloat height = self.outputSize.height;
    self[@"texelOffset"] = $(GLKVector2Make(0, 1.0 / height));
  } else {
    // Horizontal.
    CGFloat width = self.outputSize.width;
    self[@"texelOffset"] = $(GLKVector2Make(1.0 / width, 0));
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

@end
