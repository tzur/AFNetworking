// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSeparableImageProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTProgramFactory.h"
#import "LTRectDrawer.h"
#import "LTTexture.h"

@interface LTSeparableImageProcessor ()
@property (nonatomic) CGSize inputSize;
@property (nonatomic) CGSize outputSize;
@end

@implementation LTSeparableImageProcessor

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                             outputs:(NSArray<LTTexture *> *)outputs {
  return [self initWithVertexSource:vertexSource fragmentSource:fragmentSource
                      sourceTexture:sourceTexture
                  auxiliaryTextures:nil outputs:outputs];
}

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                   auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                             outputs:(NSArray<LTTexture *> *)outputs {
  if (self = [super initWithVertexSource:vertexSource fragmentSource:fragmentSource
                           sourceTexture:sourceTexture
                       auxiliaryTextures:auxiliaryTextures outputs:outputs]) {
    self.inputSize = sourceTexture.size;
    self.outputSize = [[outputs firstObject] size];
  }
  return self;
}

+ (id<LTProgramFactory>)programFactory {
  static id<LTProgramFactory> factory;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    factory = [[LTVerifierProgramFactory alloc]
               initWithRequiredUniforms:[NSSet setWithArray:@[@"texelOffset"]]];
  });

  return factory;
}

- (void)iterationStarted:(NSUInteger)iteration {
  if (!iteration) {
    // Horizontal with source width.
    CGFloat width = self.inputSize.width;
    self[@"texelOffset"] = $(LTVector2(1.0 / width, 0));
  } else if (iteration % 2) {
    // Vertical.
    CGFloat height = self.outputSize.height;
    self[@"texelOffset"] = $(LTVector2(0, 1.0 / height));
  } else {
    // Horizontal.
    CGFloat width = self.outputSize.width;
    self[@"texelOffset"] = $(LTVector2(1.0 / width, 0));
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
