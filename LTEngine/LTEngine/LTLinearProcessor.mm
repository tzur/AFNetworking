// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "LTLinearProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTLinearFsh.h"
#import "LTShaderStorage+LTPassThroughShaderVsh.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTLinearProcessor()

/// Boxed matrix used as a \c matrix proxy.
@property (strong, nonatomic) NSValue *boxedMatrix;

/// If \c YES, color gradient update should run at the next processing round of this processor.
@property (nonatomic) BOOL shouldUpdateMatrix;

/// If \c YES, color gradient update should run at the next processing round of this processor.
@property (nonatomic) BOOL shouldUpdateConstant;

@end

@implementation LTLinearProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTParameterAssert(input.size == output.size,
                    @"Provided input texture size (%g, %g) and output texture size (%g, %g) must be"
                    "of the same size",
                    input.size.height, input.size.width, output.size.height, output.size.width);

  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTLinearFsh source] input:input andOutput:output]) {
    self[[LTLinearFsh inSituProcessing]] = @(input == output);
    [self resetInputModel];
  }
  return self;
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTLinearProcessor, boxedMatrix),
      @instanceKeypath(LTLinearProcessor, constant)
    ]];
  });

  return properties;
}

- (NSValue *)defaultBoxedMatrix {
  return $(GLKMatrix4Identity);
}

- (LTVector4)defaultConstant {
  return LTVector4::zeros();
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)preprocess {
  if (self.shouldUpdateMatrix) {
    self[[LTLinearFsh matrix]] = $(self.matrix);
    self.shouldUpdateMatrix = NO;
  }

  if (self.shouldUpdateConstant) {
    self[[LTLinearFsh constant]] = $(self.constant);
    self.shouldUpdateConstant = NO;
  }
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setBoxedMatrix:(NSValue *)boxedMatrix {
  self.matrix = boxedMatrix.GLKMatrix4Value;
}

- (NSValue *)boxedMatrix {
  return $(self.matrix);
}

- (void)setMatrix:(GLKMatrix4)matrix {
  if (_matrix == matrix) {
    return;
  }

  _matrix = matrix;
  self.shouldUpdateMatrix = YES;
}

- (void)setConstant:(LTVector4)constant {
  if (_constant == constant) {
    return;
  }

  _constant = constant;
  self.shouldUpdateConstant = YES;
}

@end

NS_ASSUME_NONNULL_END
